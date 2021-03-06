local mp = require 'core.encoding.messagepack'

local tableext = require 'tableext'

local table_add_unique = tableext.add_unique
local table_prefix = tableext.prefix

local function decode_objects(t, object_ids)
  local r = {}
  local j = 1
  for i = 1, #t do
    local obj = t[i]
    -- there is a probability that some object might be removed
    if type(obj) == 'string' then
      obj = mp.decode(obj)
      obj.id = object_ids[i]
      r[j] = obj
      j = j + 1
    end
  end
  return r
end

local Repository = {}
local scripts = {}

function Repository:init_pipeline(n)
  return self.redis:init_pipeline(n)
end

function Repository:commit_pipeline()
  return self.redis:commit_pipeline()
end

-- TILES

function Repository:tiles(xmin, ymin, coords)
  local tiles = {}
  local j = 1
  for i = 2, #coords, 2 do
    local y = coords[i] + ymin
    tiles[j] = y % 2
    j = j + 1
  end
  return tiles
end

-- OBJECT

function Repository:all_objects(object_ids)
  local keys = table_prefix(object_ids, 'OBJECT:')
  return decode_objects(self.redis:mget(unpack(keys)), object_ids)
end

function Repository:add_object(id, obj)
  return self.redis:set('OBJECT:' .. id, mp.encode(obj), 'NX')
end

function Repository:get_object(id)
  local obj = self.redis:get('OBJECT:' .. id)
  if type(obj) ~= 'string' then
    return nil
  end
  return mp.decode(obj)
end

-- LOCK OBJECT

function Repository:lock_object(id)
  return self.redis:set('LOCK:OBJECT:' .. id, '', 'EX', '1', 'NX') == 'OK'
end

function Repository:unlock_object(id)
  return self.redis:del('LOCK:OBJECT:' .. id)
end

-- LIFETIME

function Repository:set_lifetime(id, lifetime)
  self.redis:zadd('LIFETIME', lifetime, id)
end

function Repository:incr_lifetime(id, delta)
  self.redis:zincrby('LIFETIME', delta, id)
end

-- MOVING

function Repository:is_moving(id)
  return self.redis:exists('MOVING:' .. id) == 1
end

function Repository:all_moving(object_ids)
  local keys = table_prefix(object_ids, 'MOVING:')
  return decode_objects(self.redis:mget(unpack(keys)), object_ids)
end

function Repository:add_moving(id, obj)
  self.redis:set('MOVING:' .. id, mp.encode(obj))
end

-- MOVETIME

function Repository:set_movetime(id, movetime)
  self.redis:zadd('MOVETIME', movetime, id)
end

-- AREA OBJECTS

function Repository:all_areas_object_ids(areas)
  return self:all_areas_id('A:OBJECTS:', areas)
end

function Repository:add_area_object_id(area, id)
  self.redis:lpush('A:OBJECTS:' .. area, id)
end

-- AREA CELL

function Repository:mark_area_cell(area, cell, value)
  if not scripts.mark_area_cell then
    scripts.mark_area_cell =
      assert(
      self.redis:script(
        'load',
        --luacov: disable
        [[
          local key = KEYS[1]
          local offset = ARGV[1]
          local value = tonumber(ARGV[2])
          local mark = redis.call('getbit', key, offset)
          if mark == value then
            return
          end
          redis.call('setbit', key, offset, value)
          return 1
        ]]
        --luacov: enable
      )
    )
  end
  return self.redis:evalsha(
    scripts.mark_area_cell,
    '1',
    'A:CELLS:' .. area,
    cell,
    value
  )
end

-- AREA MOVING

function Repository:all_areas_moving_ids(areas)
  return self:all_areas_id('A:MOVING:', areas)
end

function Repository:add_area_moving_id(area, id)
  self.redis:lpush('A:MOVING:' .. area, id)
end

-- internal details

function Repository:all_areas_id(prefix, areas)
  local n = #areas
  self.redis:init_pipeline(n)
  for i = 1, n do
    self.redis:lrange(prefix .. areas[i], '0', '-1')
  end
  local t = self.redis:commit_pipeline()
  local r = t[1]
  for i = 2, n do
    table_add_unique(r, t[i])
  end
  return r
end

function Repository:close()
  return self.redis:close()
end

--

local Metatable = {__index = Repository}

local function new(redis)
  return setmetatable({redis = redis}, Metatable)
end

return {
  new = new
}

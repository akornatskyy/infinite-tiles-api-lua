local mp = require 'core.encoding.messagepack'

local tableext = require 'tableext'

local table_add_unique = tableext.add_unique
local table_prefix = tableext.prefix

local function decode_objects(t, object_ids)
  local r = {}
  local j = 1
  for i = 1, #t do
    local obj = t[i]
    -- there is probability that some object might be removed
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
  self.redis:set('OBJECT:' .. id, mp.encode(obj))
end

-- LIFETIME

function Repository:add_lifetime(id, lifetime)
  self.redis:zadd('LIFETIME', lifetime, id)
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
  return self.redis:setbit('A:CELLS:' .. area, cell, value) ~= value
end

-- Internal details

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

--

local Metatable = {__index = Repository}

local function new(options)
  return setmetatable(options, Metatable)
end

return {
  new = new
}

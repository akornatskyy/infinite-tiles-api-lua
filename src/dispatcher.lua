local base64 = require 'core.encoding.base64'
local i18n = require 'core.i18n'
local pretty = require 'core.pretty'
local rand = require 'security.crypto.rand'

local area = require 'area'
local protocol = require 'protocol'
local tableext = require 'tableext'
local validators = require 'validators'

local area_cell_offset = area.cell_offset
local area_code_from_tile = area.code_from_tile
local area_codes = area.codes
local area_codes_sub = area.codes_sub
local base64_encode, rand_bytes = base64.encode, rand.bytes
local table_sub = tableext.sub
local time, unpack = os.time, unpack

local function newid()
  return base64_encode(rand_bytes(6))
end

local Dispatcher = {}

function Dispatcher:dispatch(message)
  local packet = protocol.decode(message)
  local packet_type = packet.t
  if not packet_type then
    return self:send_error('No packet type.')
  end
  local validator = validators[packet_type]
  if not validator then
    return self:send_error('Unknown packet type [' .. packet_type .. '].')
  end
  local errors = {}
  if not validator:validate(packet, errors, i18n.null) then
    return self:send_errors(errors)
  end
  local handler = self[packet_type]
  if not handler then
    return self:send_error('Oops, no handler for [' .. packet_type .. '].')
  end
  return handler(self, packet)
end

-- Protocol Handlers

function Dispatcher:tiles(p)
  local xmin, ymin, xmax, ymax = unpack(p.area)
  if p.coords then
    self.c:send {
      t = 'tiles',
      ref = p.ref,
      data = self.r:tiles(xmin, ymin, p.coords)
    }
  end
  local codes = area_codes(xmin, ymin, xmax, ymax)
  local t = area_codes_sub(codes, self.area_codes)
  local object_ids
  if #t > 0 then
    object_ids = self.r:all_areas_object_ids(t)
    self:send_objects(object_ids)
    self.c:subscribe(t)
  else
    object_ids = {}
  end
  t = area_codes_sub(self.area_codes, codes)
  if #t > 0 then
    self.c:unsubscribe(t)
    self:send_removed(table_sub(self.r:all_areas_object_ids(t), object_ids))
  end
  self.area_codes = codes
end

function Dispatcher:place(p)
  local x, y = p.x, p.y
  local area_code = area_code_from_tile(x, y)
  local cell = area_cell_offset(x, y)
  if not self.r:mark_area_cell(area_code, cell, '1') then
    return self:send_error('Failed to place at (' .. x .. ':' .. y .. ').')
  end
  local id = newid()
  local ok =
    self.r:add_object(
    id,
    {
      x = x,
      y = y,
      area = area_code,
      cell = cell
    }
  )
  if not ok then
    self.r:mark_area_cell(area_code, cell, '0')
    return self:send_error('Failed to add the object.')
  end
  local lifetime = time() + rand.uniform(10) + 10
  self.r:add_lifetime(id, lifetime)
  self.r:add_area_object_id(area_code, id)
  self.c:publish(
    area_code,
    {
      t = 'place',
      objects = {
        {
          id = id,
          x = x,
          y = y
        }
      }
    }
  )
end

function Dispatcher:move(p)
  local id = p.id
  if not self.r:lock_object(id) then
    return self:send_error('Unable to acquire a lock for ' .. id .. '.')
  end
  if self.r:is_moving(id) then
    self.r:unlock_object(id)
    return self:send_error('The object ' .. id .. ' is moving.')
  end
  local obj = self.r:get_object(id)
  if not obj then
    self.r:unlock_object(id)
    self.c:send {t = 'remove', objects = {id}}
    return self:send_error('The object ' .. id .. ' not found.')
  end
  local x, y = p.x, p.y
  local area_code = area_code_from_tile(x, y)
  local cell = area_cell_offset(x, y)
  if not self.r:mark_area_cell(area_code, cell, '1') then
    self.r:unlock_object(id)
    return self:send_error('Unable to acquire area cell for ' .. id .. '.')
  end
  self.r:mark_area_cell(obj.area, obj.cell, '0')

  local duration = 1 + rand.uniform(5)
  local lifetime = duration + 1 + rand.uniform(5)

  self.r:incr_lifetime(id, lifetime)
  self.r:unlock_object(id)
end

-- Internal details

function Dispatcher:send_objects(object_ids)
  if #object_ids == 0 then
    return
  end
  local t = self.r:all_objects(object_ids)
  if #t == 0 then
    return
  end
  for i = 1, #t do
    local o = t[i]
    t[i] = {
      id = o.id,
      x = o.x,
      y = o.y
    }
  end
  self.c:send {
    t = 'place',
    objects = t
  }
end

function Dispatcher:send_removed(object_ids)
  if #object_ids == 0 then
    return
  end
  self.c:send {
    t = 'remove',
    objects = object_ids
  }
end

function Dispatcher:send_error(msg)
  return self:send_errors {
    __ERROR__ = msg
  }
end

function Dispatcher:send_errors(errors)
  print(pretty.dump(errors))
  return self.c:send {
    t = 'errors',
    errors = errors
  }
end

function Dispatcher:close()
  return self.r:close()
end

--

local Metatable = {__index = Dispatcher}

local function new(client, repository)
  return setmetatable(
    {
      c = client,
      r = repository,
      area_codes = {}
    },
    Metatable
  )
end

return {
  new = new
}

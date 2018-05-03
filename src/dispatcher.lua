local base64 = require 'core.encoding.base64'
local i18n = require 'core.i18n'
local pretty = require 'core.pretty'
local rand = require 'security.crypto.rand'

local area = require 'area'
local client = require 'client'
local protocol = require 'protocol'
local repository = require 'repository'
local tableext = require 'tableext'
local validators = require 'validators'

local area_cell_offset = area.cell_offset
local area_code_from_tile = area.code_from_tile
local area_codes = area.codes
local base64_encode, rand_bytes = base64.encode, rand.bytes
local table_sub = tableext.sub
local time, unpack = os.time, unpack

local function newid()
  return base64_encode(rand_bytes(12))
end

local Dispatcher = {}

function Dispatcher:dispatch(message)
  local packet = protocol.decode(message)
  local packet_type = packet.t
  if not packet_type then
    return self:send_errors {
      __ERROR__ = 'No packet type.'
    }
  end
  local validator = validators[packet_type]
  if not validator then
    return self:send_errors {
      __ERROR__ = 'Unknown packet type [' .. packet_type .. '].'
    }
  end
  local errors = {}
  if not validator:validate(packet, errors, i18n.null) then
    return self:send_errors(errors)
  end
  local handler = self[packet_type]
  if not handler then
    return self:send_errors {
      __ERROR__ = 'Oops, no handler for [' .. packet_type .. '].'
    }
  end
  return handler(self, packet)
end

-- Protocol Handlers

function Dispatcher:send_errors(errors)
  print(pretty.dump(errors))
  return self.c:send {
    t = 'errors',
    errors = errors
  }
end

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
  local t = table_sub(codes, self.area_codes)
  if #t > 0 then
    self:send_objects(t)
    self.c:subscribe(t)
  end
  t = table_sub(self.area_codes, codes)
  if #t > 0 then
    self.c:unsubscribe(t)
    self:send_removed(t)
  end
  self.area_codes = codes
end

function Dispatcher:place(p)
  local x, y = p.x, p.y
  local area_code = area_code_from_tile(x, y)
  local cell = area_cell_offset(x, y)
  if not self.r:mark_area_cell(area_code, cell, 1) then
    return
  end
  local id = newid()
  local lifetime = time() + rand.uniform(10) + 10
  self.r:add_lifetime(id, lifetime)
  self.r:add_area_object_id(area_code, id)
  self.r:add_object(
    id,
    {
      x = x,
      y = y,
      area = area_code,
      cell = cell
    }
  )
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

-- Internal details

function Dispatcher:send_objects(areas)
  local object_ids = self.r:all_areas_object_ids(areas)
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

function Dispatcher:send_removed(areas)
  local t = self.r:all_areas_object_ids(areas)
  if #t == 0 then
    return
  end
  self.c:send {
    t = 'remove',
    objects = t
  }
end

--

local Metatable = {__index = Dispatcher}

local function new(ws, redis, subscription)
  return setmetatable(
    {
      area_codes = {},
      c = client.new {ws = ws, redis = redis, subscription = subscription},
      r = repository.new {redis = redis}
    },
    Metatable
  )
end

return {
  new = new
}

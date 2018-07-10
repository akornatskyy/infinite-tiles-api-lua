local area = require 'area'
local protocol = require 'protocol'

local area_codes = area.codes

local Sink = {}

function Sink:onmessage(message)
  if message == self.last_message then
    return
  end
  self.last_message = message
  local packet = protocol.decode(message)
  if packet.t == 'moved' then
    return protocol.encode(self:moved(packet))
  end
  return message
end

function Sink:moved(p)
  local viewport_area = self.s:get_viewport()
  if not viewport_area then
    return self:error('Oops, no viewport area.')
  end
  local codes = area_codes(unpack(viewport_area))
  if not codes[p.area] then
    return {
      t = 'remove',
      objects = {p.id}
    }
  end
  return {
    t = 'moved',
    id = p.id
  }
end

-- internal details

function Sink:error(msg)
  print(msg)
  return {
    t = 'errors',
    errors = {
      __ERROR__ = msg
    }
  }
end

--

local Metatable = {__index = Sink}

local function new(session)
  return setmetatable({s = session}, Metatable)
end

return {
  new = new
}

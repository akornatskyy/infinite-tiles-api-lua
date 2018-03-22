local pretty = require 'core.pretty'
local i18n = require 'core.i18n'

local protocol = require 'protocol'
local validators = require 'validators'
local repository = require 'repository'
local client = require 'client'

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
  local xmin, ymin = unpack(p.area)
  if p.coords then
    self.c:send {
      t = 'tiles',
      ref = p.ref,
      data = self.r:tiles(xmin, ymin, p.coords)
    }
  end
end

local function new(ws)
  return setmetatable({
    c = client.new {ws = ws},
    r = repository.new {}
  }, {__index = Dispatcher})
end

return {
  new = new
}

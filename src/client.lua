local protocol = require 'protocol'

local Client = {}

function Client:send(packet)
  self.ws:send_binary(protocol.encode(packet))
end

local function new(options)
  return setmetatable(options, {__index = Client})
end

return {
  new = new
}

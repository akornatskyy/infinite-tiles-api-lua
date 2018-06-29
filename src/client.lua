local protocol = require 'protocol'
local tableext = require 'tableext'

local table_prefix = tableext.prefix

local Client = {}

function Client:send(packet)
  self.ws:send_binary(protocol.encode(packet))
end

function Client:publish(area, packet)
  self.redis:publish('AREA:' .. area, protocol.encode(packet))
end

function Client:subscribe(areas)
  self.subscription:subscribe(table_prefix(areas, 'AREA:'))
end

function Client:unsubscribe(areas)
  self.subscription:unsubscribe(table_prefix(areas, 'AREA:'))
end

--

local Metatable = {__index = Client}

local function new(ws, redis, subscription)
  return setmetatable(
    {
      ws = ws,
      redis = redis,
      subscription = subscription
    },
    Metatable
  )
end

return {
  new = new
}

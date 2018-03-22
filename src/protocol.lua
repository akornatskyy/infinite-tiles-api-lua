local mp = require 'core.encoding.messagepack'
--local pretty = require 'core.pretty'

return {
  encode = function(packet)
    local message = mp.encode(packet)
    --print(packet.t, ' => ', pretty.dump(packet))
    return message
  end,

  decode = function(message)
    local packet = mp.decode(message)
    --print(packet.t, ' => ', pretty.dump(packet))
    return packet
  end
}

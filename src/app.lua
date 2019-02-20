local http = require 'http'
local websocket = require 'http.middleware.websocket'

local factory = require 'factory'

local app = http.app.new {
  websocket = {
    timeout = 30000, -- in milliseconds
    max_payload_len = 1024
  }
}
app:use(http.middleware.routing)

app:get('', function(w)
  return w:write('Hello World!\n')
end)

app:get('game', websocket, function(ws)
  local subscription, dispatcher, sink = factory.new(ws)

  subscription:on('message', function(channel, message)
    message = sink:onmessage(message)
    if message then
      ws:send_binary(message)
    end
  end)
  local thread = ngx.thread.spawn(function()
    return subscription:loop()
  end)

  ws:on('binary', function(message)
    dispatcher:dispatch(message)
  end)
  ws:on('timeout', function()
    ws:close()
  end)

  ws:loop()
  subscription:close()
  ngx.thread.wait(thread)
  dispatcher:close()
end)

return app()

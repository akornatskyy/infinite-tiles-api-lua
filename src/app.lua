local http = require 'http'

local factory = require 'factory'
local websocket = require 'websocket'

local app = http.app.new {
  websocket = {
    timeout = 30000 -- in milliseconds
    -- max_payload_len = 65535
  }
}
app:use(http.middleware.routing)

app:get('', function(w)
  return w:write('Hello World!\n')
end)

app:get('game', websocket, function(ws)
  local subscription, dispatcher = factory.new(ws)

  subscription:on('message', function(channel, message)
    ws:send_binary(message)
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

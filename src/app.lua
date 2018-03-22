local http = require 'http'

local websocket = require 'websocket'
local dispatcher = require 'dispatcher'

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
  local d = dispatcher.new(ws)
  ws:on('binary', function(message)
    d:dispatch(message)
  end)
  ws:on('timeout', function()
    ws:close()
  end)
  ws:loop()
  print('done')
end)

return app()

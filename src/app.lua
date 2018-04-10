local http = require 'http'

local websocket = require 'websocket'
local redis = require 'resty.redis'
local subscription = require 'subscription'

local dispatcher = require 'dispatcher'

local redis_host = os.getenv('REDIS_HOST') or '127.0.0.1'

local function make_redis()
  local r = redis.new()
  r:connect(redis_host, 6379)
  r:set_timeout(0)
  return r
end

local function make_subscription()
  return subscription.new {
    host = redis_host,
    port = 6379,
    timeout = 0, -- in milliseconds
    retry_strategy = function(err)
      ngx.sleep(1)
      return true
    end
  }
end

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
  local s = make_subscription()
  s:on('message', function(channel, message)
    ws:send_binary(message)
  end)

  local r = make_redis()
  local d = dispatcher.new(ws, r, s)
  ws:on('binary', function(message)
    d:dispatch(message)
  end)
  ws:on('timeout', function()
    ws:close()
  end)

  local thread = ngx.thread.spawn(function()
    return s:loop()
  end)
  ws:loop()
  r:close()
  s:close()
  ngx.thread.wait(thread)
end)

return app()

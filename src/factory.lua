local redis = require 'resty.redis'

local client = require 'client'
local dispatcher = require 'dispatcher'
local repository = require 'repository'
local subscription = require 'subscription'

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

local function new(ws)
  local s = make_subscription()
  local r = make_redis()
  local d = dispatcher.new(client.new(ws, r, s), repository.new(r))
  return s, d
end

return {
  new = new
}

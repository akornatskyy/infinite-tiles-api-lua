local base64 = require 'core.encoding.base64'
local rand = require 'security.crypto.rand'
local redis = require 'resty.redis'

local client = require 'client'
local dispatcher = require 'dispatcher'
local repository = require 'repository'
local session = require 'session'
local subscription = require 'subscription'

local base64_encode, rand_bytes = base64.encode, rand.bytes
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

local function make_session_id()
  return base64_encode(rand_bytes(6))
end

local function new(ws)
  local se = session.new(make_session_id(), ngx.shared.viewports)
  local su = make_subscription()
  local r = make_redis()
  local d = dispatcher.new(se, client.new(ws, r, su), repository.new(r))
  return su, d
end

return {
  new = new
}

--local pretty = require 'core.pretty'
local redis = require 'resty.redis'

-- see rationale behind here:
-- https://github.com/openresty/lua-resty-redis/issues/131
-- https://github.com/openresty/lua-resty-redis/issues/132
local function make_req(command, args)
  local nargs = #args
  local r = table.new(nargs * 2 + 2, 0)
  r[1] = '*' .. (nargs + 1) .. '\r\n$' .. #command .. '\r\n' .. command
  local j = 2
  for i = 1, nargs do
    local arg = args[i]
    r[j] = '\r\n$' .. #arg .. '\r\n'
    r[j + 1] = arg
    j = j + 2
  end
  r[j] = '\r\n'
  --print(pretty.dump(r))
  return r
end

local Subscription = {}

local function send(self, command, args)
  --print(command .. ' ' .. pretty.dump(args))
  local sock = rawget(self.redis, '_sock')
  return sock:send(make_req(command, args))
end

local function connect(self)
  local r = self.redis
  while self.running do
    local ok, err = r:connect(self.options.host, self.options.port)
    if not ok then
      print(err)
      ok, err = self.options.retry_strategy(err)
      if not ok then
        return ok, err
      end
    else
      self.redis:set_timeout(self.options.timeout)
      -- subscribe to channels
      for command, channels in next, self.channels do
        if #channels ~= 0 then
          ok, err = send(self, command, channels)
          if not ok then
            return ok, err
          end
        end
      end
      self.redis._subscribed = true
      return true
    end
  end
end

local function subscribe(self, command, channels)
  local subscribed = self.channels[command]
  for _, channel in next, channels do
    table.insert(subscribed, channel)
  end
  if self.running then
    local bytes, err = send(self, command, channels)
    if not bytes then
      return false, err
    end
  end
  return true
end

local function unsubscribe(self, command, channels)
  if self.running then
    local bytes, err = send(self, command, channels)
    if not bytes then
      return false, err
    end
  end
  return true
end

function Subscription:ping(message)
  return send(self, 'ping', {message})
end

function Subscription:quit()
  return send(self, 'quit', {})
end

function Subscription:on(cmd, handler)
  self.commands[cmd] = handler
end

function Subscription:subscribe(channels)
  return subscribe(self, 'subscribe', channels)
end

function Subscription:psubscribe(channels)
  return subscribe(self, 'psubscribe', channels)
end

function Subscription:unsubscribe(channels)
  return unsubscribe(self, 'unsubscribe', channels)
end

function Subscription:punsubscribe(channels)
  return unsubscribe(self, 'punsubscribe', channels)
end

function Subscription:loop()
  self.running = true
  connect(self)
  while self.running do
    local res, err = self.redis:read_reply()
    if not res then
      print(err)
      if not self.options.retry_strategy(err) or not connect(self) then
        break
      end
    else
      --print(pretty.dump(res))
      local cmd = res[1]
      local handler = self.commands[cmd]
      if handler then
        handler(unpack(res, 2))
      end
      local subscribed = self.uchannels[cmd]
      if subscribed then
        local channel = res[2]
        -- unsubscribe channel
        for i = #subscribed, 1, -1 do
          if channel == subscribed[i] then
            table.remove(subscribed, i)
            break
          end
        end
        if res[3] == 0 then
          break
        end
      end
    end
  end
  self.running = false
  self.redis:close()
end

function Subscription:close()
  if #self.channels.subscribe > 0 then
    unsubscribe(self, 'unsubscribe', {})
  end
  if #self.channels.psubscribe > 0 then
    unsubscribe(self, 'punsubscribe', {})
  end
  self:quit()
  self.running = false
end

--

local Metatable = {__index = Subscription}

local function new(options)
  local subscribed = {}
  local psubscribed = {}
  return setmetatable(
    {
      options = options,
      redis = redis.new(),
      commands = {},
      channels = {subscribe = subscribed, psubscribe = psubscribed},
      uchannels = {unsubscribe = subscribed, punsubscribe = psubscribed}
    },
    Metatable
  )
end

return {
  new = new
}

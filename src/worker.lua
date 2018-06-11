local redis = require 'redis'
local socket = require 'socket'

local time, sleep = socket.gettime, socket.sleep

local sources = {
  ['LIFETIME'] = [[
    local id = ARGV[1]
    local lock = 'LOCK:OBJECT:' .. id
    if not redis.call('set', lock, '', 'EX', '1', 'NX') then
      return false
    end
    local o = redis.call('get', 'OBJECT:' .. id)
    if o then
      o = cmsgpack.unpack(o)
      redis.call('lrem', 'A:OBJECTS:' .. o.area, '1', id)
      redis.call('setbit', 'A:CELLS:' .. o.area, o.cell, 0)
      redis.call('del', 'OBJECT:' .. id)
      local e = cmsgpack.pack {
        t = 'remove',
        objects = {id}
      }
      redis.call('publish', 'AREA:' .. o.area, e)
    end
    redis.call('zrem', 'LIFETIME', id)
    redis.call('del', lock)
    return true
  ]]
}

local function log(msg)
  print(os.date('%Y/%m/%d %T ') .. msg)
end

local function run()
  local r = redis.connect(os.getenv('REDIS_HOST') or '127.0.0.1', 6379)
  log('connected')
  local scripts = {}
  for key, script in next, sources do
    scripts[key] = r:script('load', script)
  end
  while true do
    local timestamp = math.floor(time())
    for key, script in next, scripts do
      local t = r:zrangebyscore(key, '0', tostring(timestamp))
      if #t ~= 0 then
        for _, id in next, t do
          if r:evalsha(script, '0', id) then
            log(key .. ' ' .. id)
          end
        end
      end
    end
    local delta = timestamp + 1 - time()
    if delta > 0 then
      sleep(delta)
    end
  end
end

local function main()
  while true do
    local _, err = pcall(run)
    if not err then
      break
    end
    if not string.find(err, 'connection', 1, true) then
      log(err)
      break
    end
    log('reconnecting in 2 secs...')
    sleep(2)
  end
end

if debug.getinfo(3) == nil then
  return main()
end

return {
  sources = sources
}

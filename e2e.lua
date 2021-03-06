local ev = require 'ev'
local pretty = require 'core.pretty'
local rand = require 'security.crypto.rand'
local websocket = require 'websocket.client'

local protocol = require 'protocol'

local loop = ev.Loop.default

-- helpers

local function now()
  return loop:now()
end

local function logger(name)
  name = ' [' .. name .. '] '
  return function(msg)
    print(os.date('%T', now()) .. name .. msg)
  end
end

local function warn(msg)
  return 'WARN ' .. msg
end

local function err(msg)
  return 'ERR ' .. msg
end

local function table_length(t)
  local c = 0
  for _ in next, t do
    c = c + 1
  end
  return c
end

-- math

local Spring = {}

function Spring:update(delta)
  local pos = self.pos
  local x, y = pos.x, pos.y
  local l = math.sqrt(x * x + y * y)
  local s = l - self.l
  local kx = 0
  local ky = 0
  if s > 0 then
    local k = self.k * s / l
    kx = k * x
    ky = k * y
  end

  local v = self.velocity
  local b, vx, vy = self.b, v.x, v.y
  vx = vx + delta * (kx + b * vx)
  vy = vy + delta * (ky + b * vy)
  v.x = vx
  v.y = vy

  x = x + delta * vx
  y = y + delta * vy
  pos.x = x
  pos.y = y
  return x, y
end

local function spring(self)
  assert(self.pos) -- position
  assert(self.k) -- spring constant
  assert(self.b) -- viscous damping coefficient
  assert(self.l) -- spring length at rest
  self.velocity = {x = 0, y = 0}
  return setmetatable(self, {__index = Spring})
end

local Stats = {}

function Stats:incr(name)
  local c = self.counters[name]
  if not c then
    c = 1
  else
    c = c + 1
  end
  self.counters[name] = c
end

local function stats()
  return setmetatable({counters = {}}, {__index = Stats})
end

--

local Player = {}

function Player:on_open()
  self.log('connected')
  self.now = now()
  self:on_ping()
  self.update_timer:start(loop, true)
  self.ping_timer:start(loop, true)
  self.apply_force_timer:start(loop, true)
  self.timer:start(loop, true)
end

function Player:on_error(msg)
  self.log(err(msg))
  loop:unloop()
  os.exit(1)
end

function Player:send(p)
  self.log('>>> ' .. pretty.dump(p))
  self.out_stats:incr(p.t)
  self.ws:send(protocol.encode(p), 2)
end

function Player:on_update(delta)
  local x, y = self.spring:update(delta)
  x = math.floor(x)
  y = math.floor(y)
  if self.area[1] ~= x or self.area[2] ~= y then
    local dx = 11 + rand.uniform(2)
    local dy = 22 + rand.uniform(2)
    self.area = {x, y, dx, dy}
    local p = {t = 'tiles', area = self.area}
    if rand.uniform(3) == 1 then
      p.coords = {0, 0, 0, 1, 0, 2, 1, 0, 1, 1, 1, 2, 2, 0, 2, 1, 2, 2}
    end
    self:send(p)
  end
end

function Player:on_ping()
  self:send {t = 'ping', time = now()}
end

function Player:on_apply_force()
  local v = self.spring.velocity
  v.x = v.x + (rand.uniform(101) - 50) / 20
  v.y = v.y + (rand.uniform(101) - 50) / 20
end

function Player:on_place_or_move()
  local l = table_length(self.objects)
  local x, y, dx, dy = unpack(self.area)
  dx = math.floor(dx / 3)
  dy = math.floor(dy / 3)
  x = x + dx + rand.uniform(dx)
  y = y + dy + rand.uniform(dy)
  if l < dx * dy / 2 then
    self:send {t = 'place', x = x, y = y}
  else
    local id = next(self.objects)
    self:send {t = 'move', id = id, x = x, y = y}
  end
end

function Player:on_message(p)
  self.log('<<< ' .. pretty.dump(p))
  self.in_stats:incr(p.t)
  local handler = self[p.t]
  if handler then
    handler(self, p)
  end
end

function Player:place(p)
  for _, o in next, p.objects do
    self.objects[o.id] = true
  end
end

function Player:move(p)
  for _, o in next, p.objects do
    self.objects[o.id] = nil
    self.moving[o.id] = true
  end
end

function Player:moved(p)
  local id = p.id
  self.objects[id] = self.moving[id]
  self.moving[id] = nil
end

function Player:remove(p)
  for _, id in next, p.objects do
    self.objects[id] = nil
  end
end

function Player:stats()
  local c = self.in_stats.counters
  self.log('stats outgoing: ' .. pretty.dump(self.out_stats.counters))
  self.log('stats incoming: ' .. pretty.dump(c))
  if not c.pong or not c.place or not c.remove or not c.move or not c.moved then
    self.log(warn('is worker alive?'))
  end
end

local function player(id)
  local self = {
    log = logger(id),
    spring = spring {
      pos = {x = -5, y = -9},
      k = -0.25,
      b = -0.05,
      l = 4
    },
    time = 0,
    area = {0, 0},
    objects = {},
    moving = {},
    in_stats = stats(),
    out_stats = stats()
  }
  local ws = websocket.ev {loop = loop}
  ws:on_open(
    function()
      self:on_open()
    end
  )
  ws:on_close(
    function()
      self:on_error('connection closed')
    end
  )
  ws:on_message(
    function(_, msg)
      self:on_message(protocol.decode(msg))
    end
  )
  ws:on_error(
    function(_, msg)
      self:on_error(msg)
    end
  )
  self.ws = ws
  self.update_timer =
    ev.Timer.new(
    function()
      local t = now()
      self:on_update(t - self.now)
      self.now = t
    end,
    1,
    1 / 60
  )
  self.ping_timer =
    ev.Timer.new(
    function()
      self:on_ping()
    end,
    1,
    1
  )
  self.apply_force_timer =
    ev.Timer.new(
    function()
      self:on_apply_force()
    end,
    2,
    2
  )
  self.timer =
    ev.Timer.new(
    function()
      self:on_place_or_move()
    end,
    2,
    1 / 4
  )
  setmetatable(self, {__index = Player})
  ws:connect('ws://localhost:8080/game')
  return self
end

local function run(n, timeout)
  local log = logger('main')
  log('spawning ' .. n .. ' for ' .. timeout .. ' seconds')

  ev.Timer.new(loop.unloop, timeout):start(loop)
  local t = {}
  for i = 1, n do
    t[i] = player(string.char(64 + i))
  end

  loop:loop()

  for i = 1, n do
    t[i]:stats()
  end

  log('done')
end

run(arg[1] or 1, arg[2] or 10)

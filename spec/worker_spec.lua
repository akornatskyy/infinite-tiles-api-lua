local function load(script)
  local f = 'return function(ARGV)\n' .. script .. '\nend'
  return assert(loadstring(f))()
end

local function setup_redis(expected)
  local i = 1
  _G.redis.call = function(...)
    local args, result = unpack(expected[i])
    assert.same(args, {...})
    i = i + 1
    return result
  end
end

insulate('worker', function()
  package.loaded.redis = {}
  package.loaded.socket = {}
  local worker = require 'worker'
  _G.redis = {}
  _G.cmsgpack = {
    unpack = function(d) return d end,
    pack = function(d) return d end
  }

  describe('lifetime script', function()
    local f = load(worker.sources.LIFETIME)

    it('returns if object lock cannot be acquired', function()
      setup_redis {
        {{'set', 'LOCK:OBJECT:123', '', 'EX', '1', 'NX'}, false}
      }

      assert.is_false(f {'123'})
    end)

    it('clean ups if object is not available', function()
      setup_redis {
        {{'set', 'LOCK:OBJECT:123', '', 'EX', '1', 'NX'}, true},
        {{'get', 'OBJECT:123'}},
        {{'zrem', 'LIFETIME', '123'}},
        {{'del', 'LOCK:OBJECT:123'}}
      }

      assert.is_true(f {'123'})
    end)

    it('removes object that is not moving', function()
      local mock_msgpack = mock(_G.cmsgpack)
      local object = {area = 'N0W0', cell = 5}
      local packet = {t = 'remove', objects = {'123'}}
      setup_redis {
        {{'set', 'LOCK:OBJECT:123', '', 'EX', '1', 'NX'}, true},
        {{'get', 'OBJECT:123'}, object},
        {{'lrem', 'A:OBJECTS:N0W0', '1', '123'}},
        {{'setbit', 'A:CELLS:N0W0', 5, 0}},
        {{'del', 'OBJECT:123'}},
        {{'publish', 'AREA:N0W0', packet}},
        {{'get', 'MOVING:123'}},
        {{'zrem', 'LIFETIME', '123'}},
        {{'del', 'LOCK:OBJECT:123'}}
      }

      assert.is_true(f {'123'})

      assert.spy(mock_msgpack.unpack).was.called_with(object)
      assert.spy(mock_msgpack.pack).was.called_with(packet)
    end)

    it('removes object that is moving in the same area', function()
      local mock_msgpack = mock(_G.cmsgpack)
      local object = {area = 'N0W0', cell = 5}
      local packet = {t = 'remove', objects = {'123'}}
      local moving = {area = object.area, cell = 7}
      setup_redis {
        {{'set', 'LOCK:OBJECT:123', '', 'EX', '1', 'NX'}, true},
        {{'get', 'OBJECT:123'}, object},
        {{'lrem', 'A:OBJECTS:N0W0', '1', '123'}},
        {{'setbit', 'A:CELLS:N0W0', 5, 0}},
        {{'del', 'OBJECT:123'}},
        {{'publish', 'AREA:N0W0', packet}},
        {{'get', 'MOVING:123'}, moving},
        {{'lrem', 'A:MOVING:N0W0', '1', '123'}},
        {{'del', 'MOVING:123'}},
        {{'zrem', 'LIFETIME', '123'}},
        {{'del', 'LOCK:OBJECT:123'}}
      }

      assert.is_true(f {'123'})

      assert.spy(mock_msgpack.unpack).was.called_with(object)
      assert.spy(mock_msgpack.unpack).was.called_with(moving)
      assert.spy(mock_msgpack.pack).was.called_with(packet)
    end)

    it('removes object that is moving across areas', function()
      local mock_msgpack = mock(_G.cmsgpack)
      local object = {area = 'N0W0', cell = 5}
      local packet = {t = 'remove', objects = {'123'}}
      local moving = {area = 'S0E0', cell = 7}
      setup_redis {
        {{'set', 'LOCK:OBJECT:123', '', 'EX', '1', 'NX'}, true},
        {{'get', 'OBJECT:123'}, object},
        {{'lrem', 'A:OBJECTS:N0W0', '1', '123'}},
        {{'setbit', 'A:CELLS:N0W0', 5, 0}},
        {{'del', 'OBJECT:123'}},
        {{'publish', 'AREA:N0W0', packet}},
        {{'get', 'MOVING:123'}, moving},
        {{'lrem', 'A:MOVING:N0W0', '1', '123'}},
        {{'lrem', 'A:MOVING:S0E0', '1', '123'}},
        {{'lrem', 'A:OBJECTS:S0E0', '1', '123'}},
        {{'setbit', 'A:CELLS:S0E0', 7, 0}},
        {{'publish', 'AREA:S0E0', packet}},
        {{'del', 'MOVING:123'}},
        {{'zrem', 'LIFETIME', '123'}},
        {{'del', 'LOCK:OBJECT:123'}}
      }

      assert.is_true(f {'123'})

      assert.spy(mock_msgpack.unpack).was.called_with(object)
      assert.spy(mock_msgpack.unpack).was.called_with(moving)
      assert.spy(mock_msgpack.pack).was.called_with(packet)
    end)
  end)
end)

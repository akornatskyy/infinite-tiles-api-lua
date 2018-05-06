local describe, it, assert = describe, it, assert

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

describe('worker', function()
  insulate('lifetime script', function()
    package.loaded.redis = {}
    package.loaded.socket = {}
    local worker = require 'worker'
    _G.redis = {}
    _G.cmsgpack = {
      unpack = function(d) return d end,
      pack = function(d) return d end
    }
    local f = load(worker.sources.LIFETIME)

    it('returns if lock cannot be acquired', function()
      setup_redis {
        {{'set', 'LOCK:LIFETIME:123', '', 'EX', '1', 'NX'}, false}
      }

      assert.is_false(f {'123'})
    end)

    it('clean ups if object is not available', function()
      setup_redis {
        {{'set', 'LOCK:LIFETIME:123', '', 'EX', '1', 'NX'}, true},
        {{'get', 'OBJECT:123'}},
        {{'zrem', 'LIFETIME', '123'}},
        {{'del', 'LOCK:LIFETIME:123'}}
      }

      assert.is_true(f {'123'})
    end)
  end)
end)

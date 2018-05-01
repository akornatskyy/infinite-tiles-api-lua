local tableext = require 'tableext'

local describe, it, assert = describe, it, assert

describe('tableext', function()
  describe('sub', function()
    it('returns keys from t1 not present in t2', function()
      local cases = {
        {{}, {}, {}},
        {{'a'}, {a = 1}, {}},
        {{}, {}, {a = 1}},
        {{'a'}, {a = 1, b = 1}, {b = 1, c = 1}}
      }
      for _, args in next, cases do
        local expected, t1, t2 = unpack(args)
        local r = tableext.sub(t1, t2)
        assert.same(expected, r)
      end
    end)
  end)

  describe('prefix', function()
    it('returns a table with all elements prefixed', function()
      local r = tableext.prefix({'k1', 'k2'}, 'prefix:')
      assert.same({'prefix:k1', 'prefix:k2'}, r)
    end)
  end)
end)

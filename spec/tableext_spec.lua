local tableext = require 'tableext'

describe('tableext', function()
  describe('prefix', function()
    it('returns a table with all elements prefixed', function()
      local r = tableext.prefix({'k1', 'k2'}, 'prefix:')
      assert.same({'prefix:k1', 'prefix:k2'}, r)
    end)
  end)

  describe('add unique', function()
    it('add only unique elements', function()
      local cases = {
        {{}, {}, {}},
        {{'a'}, {'a'}, {}},
        {{'b'}, {}, {'b'}},
        {{'c'}, {'c'}, {'c'}},
        {{'d'}, {}, {'d', 'd'}},
        {{'a', 'b', 'c'}, {}, {'a', 'a', 'b', 'b', 'c'}},
        {{'a', 'b', 'c', 'd'}, {'a', 'b'}, {'a', 'a', 'b', 'b', 'c', 'd', 'd'}}
      }
      for _, args in next, cases do
        local expected, t1, t2 = unpack(args)
        tableext.add_unique(t1, t2)
        assert.same(expected, t1)
      end
    end)
  end)

  describe('subtract tables', function()
    it('removes elements from t1 which are in t2.', function()
      local cases = {
        {{}, {}, {}},
        {{'a'}, {'a'}, {}},
        {{'a'}, {'a'}, {'b'}},
        {{'a'}, {'a', 'b'}, {'b', 'c'}},
        {{}, {}, {'b'}},
        {{}, {'c'}, {'c'}},
        {{}, {}, {'d', 'd'}},
        {{}, {'a', 'c'}, {'a', 'b', 'c', 'd'}}
      }
      for _, args in next, cases do
        local expected, t1, t2 = unpack(args)
        tableext.sub(t1, t2)
        assert.same(expected, t1)
      end
    end)
  end)
end)

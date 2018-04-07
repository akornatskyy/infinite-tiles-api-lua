local tableext = require 'tableext'

local describe, it, assert = describe, it, assert

describe('tableext', function()
  describe('prefix', function()
    it('returns a table with all elements prefixed', function()
      local r = tableext.prefix({'k1', 'k2'}, 'prefix:')
      assert.same({'prefix:k1', 'prefix:k2'}, r)
    end)
  end)
end)

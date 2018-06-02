local area = require 'area'

local describe, it, assert = describe, it, assert

describe('area', function()
  describe('code', function()
    it('returns code from coordinates', function()
      local cases = {
        {'S0E0', 0, 0},
        {'N2W1', -1, -2},
        {'S2W1', -1, 2},
        {'S2E1', 1, 2},
        {'N2E1', 1, -2},
      }
      for _, args in next, cases do
        local expected, x, y = unpack(args)
        local r = area.code(x, y)
        assert.equals(expected, r)
      end
    end)
  end)

  describe('code_from_tile', function()
    it('returns code from tile coordinates', function()
      local cases = {
        {'S0E0', 0, 0},
        {'S0E0', 2, 4},
        {'N2W1', -1, -9},
        {'N2W1', -4, -16},
        {'S2W1', -1, 16},
        {'S2W1', -4, 23},
        {'S2E1', 4, 16},
        {'S2E1', 7, 23},
        {'N2E1', 4, -9},
        {'N2E1', 7, -16}
      }
      for _, args in next, cases do
        local expected, x, y = unpack(args)
        local r = area.code_from_tile(x, y)
        assert.equals(expected, r)
      end
    end)
  end)

  describe('cell_offset', function()
    it('returns cell offset from tile coordinates', function()
      local cases = {
        {0, 0, 0},
        {2, 2, 0},
        {7, 3, 1},
        {9, 1, 2},
        {17, 117, 268},
      }
      for _, args in next, cases do
        local expected, x, y = unpack(args)
        local r = area.cell_offset(x, y)
        assert.equals(expected, r)
      end

      for x=-50, 50 do
        for y=-50, 50 do
          local r = area.cell_offset(x, y)
          assert.is_true(r >= 0)
          assert.is_true(r <= 31)
        end
      end
    end)
  end)

  describe('codes', function()
    it('returns area codes associated with given rectangle', function()
      local cases = {
        {{N1E0=true, N1W1=true, S0E0=true, S0W1=true}, -1, -1, 1, 1},
        {{S0E0=true}, 0, 0, 1, 1},
      }
      for _, args in next, cases do
        local expected, x1, y1, x2, y2 = unpack(args)
        local r = area.codes(x1, y1, x2, y2)
        assert.same(expected, r)
      end
    end)
  end)

  describe('codes_sub', function()
    it('returns area codes from t1 not present in t2', function()
      local cases = {
        {{}, {}, {}},
        {{'a'}, {a = 1}, {}},
        {{}, {}, {a = 1}},
        {{'a'}, {a = 1, b = 1}, {b = 1, c = 1}}
      }
      for _, args in next, cases do
        local expected, t1, t2 = unpack(args)
        local r = area.codes_sub(t1, t2)
        assert.same(expected, r)
      end
    end)
  end)
end)

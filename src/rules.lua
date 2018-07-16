local next = next

local AllowedFields = {
  __index = {
    validate = function(self, value, model)
      for name in next, model do
        if not self.allowed[name] then
          return 'Unknown field name [' .. name .. '].'
        end
      end
      return nil
    end
  }
}

local function allowed_fields(t)
  local allowed = {}
  for i = 1, #t do
    allowed[t[i]] = true
  end
  return setmetatable({allowed = allowed}, AllowedFields)
end

local number = {
  validate = function(self, value, model)
    if not value then
      return 'Required field cannot be left blank.'
    end
    if type(value) ~= 'number' then
      return 'Must be a number value.'
    end
    return nil
  end
}

local integer = {
  validate = function(self, value, model)
    if not value then
      return 'Required field cannot be left blank.'
    end
    if type(value) ~= 'number' or value % 1 ~= 0 then
      return 'Must be an integer value.'
    end
    return nil
  end
}

local area = {
  validate = function(self, value, model)
    if not value or type(value) ~= 'table' then
      return 'Must be a list value.'
    end
    if #value ~= 4 then
      return 'The list must have exactly four integers.'
    end
    for _, n in next, value do
      if type(n) ~= 'number' or n % 1 ~= 0 then
        return 'The list must have integers only.'
      end
    end
    local xmin, ymin, dx, dy = unpack(value)
    if xmin < -100 or xmin > 100 then
      return 'The xmin must be [-100, 100].'
    end
    if ymin < -100 or ymin > 100 then
      return 'The ymin must be [-100, 100].'
    end
    if dx < 0 or dx > 12 then
      return 'The dx must be [0, 12].'
    end
    if dy < 0 or dy > 23 then
      return 'The dy must be [0, 23].'
    end
    return nil
  end
}

local coords = {
  validate = function(self, value, model)
    if not value then
      return nil
    end
    if type(value) ~= 'table' then
      return 'Must be a list value.'
    end
    if #value % 2 ~= 0 then
      return 'Must include pairs.'
    end
    -- 12 * 23 * 2 = 552
    if #value > 624 then
      return 'Exceeds maximum length of 624.'
    end
    for _, n in next, value do
      if type(n) ~= 'number' or n % 1 ~= 0 then
        return 'The list must have integers only.'
      end
      if n < 0 or n > 23 then
        return 'The coords must be relative.'
      end
    end
    return nil
  end
}

return {
  allowed_fields = allowed_fields,
  area = area,
  coords = coords,
  integer = integer,
  number = number
}

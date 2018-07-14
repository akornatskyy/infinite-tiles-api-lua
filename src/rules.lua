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

return {
  allowed_fields = allowed_fields,
  number = number,
  integer = integer
}

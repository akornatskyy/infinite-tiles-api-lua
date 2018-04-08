local next = next

local AllowedKeys = {
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

local function allowed_keys(t)
  local allowed = {}
  for i = 1, #t do
    allowed[t[i]] = true
  end
  return setmetatable({allowed = allowed}, AllowedKeys)
end

local number = {
  validate = function(self, value, model)
    if not value or type(value) ~= 'number' then
      return 'Must be an integer value.'
    end
    return nil
  end
}

return {
  allowed_keys = allowed_keys,
  number = number
}

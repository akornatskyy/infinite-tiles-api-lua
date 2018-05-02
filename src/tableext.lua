-- Returns keys from t1 which are not in t2.
local function table_sub(t1, t2)
  local r = {}
  local i = 1
  for key in next, t1 do
    if not t2[key] then
      r[i] = key
      i = i + 1
    end
  end
  return r
end

local function table_prefix(t, prefix)
  local r = {}
  for i = 1, #t do
    r[i] = prefix .. t[i]
  end
  return r
end

local function table_add_unique(t1, t2)
  for i = 1, #t2 do
    local found = false
    local value = t2[i]
    local n = #t1
    for j = 1, n do
      found = t1[j] == value
      if found then
        break
      end
    end
    if not found then
      t1[n + 1] = value
    end
  end
end

return {
  sub = table_sub,
  prefix = table_prefix,
  add_unique = table_add_unique
}

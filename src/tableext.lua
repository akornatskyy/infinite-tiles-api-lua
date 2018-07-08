local function table_prefix(t, prefix)
  local r = {}
  for i = 1, #t do
    r[i] = prefix .. t[i]
  end
  return r
end

local function table_add_unique(t1, t2)
  local n = #t1
  for i = 1, #t2 do
    local found = false
    local value = t2[i]
    for j = 1, n do
      found = t1[j] == value
      if found then
        break
      end
    end
    if not found then
      n = n + 1
      t1[n] = value
    end
  end
end

-- Removes elements from t1 which are in t2.
local function table_sub(t1, t2)
  local n = #t2
  for i = #t1, 1, -1 do
    local value = t1[i]
    for j = 1, n do
      if value == t2[j] then
        table.remove(t1, i)
        break
      end
    end
  end
  return t1
end

return {
  prefix = table_prefix,
  add_unique = table_add_unique,
  sub = table_sub
}

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

return {
  sub = table_sub,
  prefix = table_prefix
}

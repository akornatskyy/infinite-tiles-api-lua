local function table_prefix(t, prefix)
  local r = {}
  for i = 1, #t do
    r[i] = prefix .. t[i]
  end
  return r
end

return {
  prefix = table_prefix
}

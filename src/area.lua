local area_size_x = 4
local area_size_y = 8

local function code(x, y)
  return (y < 0 and 'N' .. - y or 'S' .. y) ..
  (x < 0 and 'W' .. - x or 'E' .. x)
end

local function code_from_tile(x, y)
  return code(math.floor(x / area_size_x), math.floor(y / area_size_y))
end

local function cell_offset(x, y)
  return area_size_x * (y % area_size_y) + x % area_size_x
end

local function codes(xmin, ymin, dx, dy)
  local x1 = math.floor(xmin / area_size_x)
  local y1 = math.floor(ymin / area_size_y)
  local x2 = math.floor((xmin + dx) / area_size_x)
  local y2 = math.floor((ymin + dy) / area_size_y)
  local c = {}
  for y = y1, y2 do
    for x = x1, x2 do
      c[code(x, y)] = true
    end
  end
  return c
end

-- Returns a list of area codes from t1 which are not in t2.
local function codes_sub(t1, t2)
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

local function codes_intersect(t1, t2)
  local r = {}
  local i = 1
  for key in next, t1 do
    if t2[key] then
      r[i] = key
      i = i + 1
    end
  end
  return r
end

return {
  cell_offset = cell_offset,
  code = code,
  code_from_tile = code_from_tile,
  codes = codes,
  codes_intersect = codes_intersect,
  codes_sub = codes_sub
}

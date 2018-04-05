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

local function codes(x1, y1, x2, y2)
  x1 = math.floor(x1 / area_size_x)
  y1 = math.floor(y1 / area_size_y)
  x2 = math.floor(x2 / area_size_x)
  y2 = math.floor(y2 / area_size_y)
  local c = {}
  for y = y1, y2 do
    for x = x1, x2 do
      c[code(x, y)] = true
    end
  end
  return c
end

return {
  code = code,
  code_from_tile = code_from_tile,
  cell_offset = cell_offset,
  codes = codes
}

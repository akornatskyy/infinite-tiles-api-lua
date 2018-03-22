local Repository = {}

-- TILES

function Repository:tiles(xmin, ymin, coords)
  local tiles = {}
  local j = 1
  for i = 2, #coords, 2 do
    local y = coords[i] + ymin
    tiles[j] = y % 2
    j = j + 1
  end
  return tiles
end

local function new(options)
  return setmetatable(options, {__index = Repository})
end

return {
  new = new
}

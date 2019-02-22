local unpack = unpack

local function area(value)
  if #value ~= 4 then
    return 'The area list must have exactly four integers.'
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

local function coords(value)
  if #value % 2 ~= 0 then
    return 'Must include pairs.'
  end
  -- 12 * 23 * 2 = 552
  if #value > 624 then
    return 'Exceeds maximum length of 624.'
  end
end

return {
  area = area,
  coords = coords
}

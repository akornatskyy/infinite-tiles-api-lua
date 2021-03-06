local mp = require 'protocol'

local Session = {}

-- VIEWPORT

function Session:set_viewport(area)
  self.viewports:set('VIEWPORT:' .. self.session_id, mp.encode(area))
end

function Session:get_viewport()
  local area = self.viewports:get('VIEWPORT:' .. self.session_id)
  if type(area) ~= 'string' then
    return nil
  end
  return mp.decode(area)
end

function Session:close()
  self.viewports:delete('VIEWPORT:' .. self.session_id)
end

--

local Metatable = {__index = Session}

local function new(session_id, viewports)
  return setmetatable(
    {
      session_id = session_id,
      viewports = viewports
    },
    Metatable
  )
end

return {
  new = new
}

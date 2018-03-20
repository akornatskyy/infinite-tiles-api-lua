local http = require 'http'

local app = http.app.new()
app:use(http.middleware.routing)

app:get('', function(w)
  return w:write('Hello World!\n')
end)

return app()

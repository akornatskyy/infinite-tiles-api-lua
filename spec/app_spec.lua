local request = require 'http.functional.request'
local writer = require 'http.functional.response'

insulate('app hello', function()
	package.loaded['resty.websocket.server'] = {}
	package.loaded['resty.redis'] = {}
	_G.ngx = {}
	local app = require 'app'

	it('responds with hello', function()
    local w, req = writer.new(), request.new()
    app(w, req)
    assert.same({'Hello World!\n'}, w.buffer)
  end)
end)

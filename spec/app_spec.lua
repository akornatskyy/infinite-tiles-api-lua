local request = require 'http.functional.request'
local writer = require 'http.functional.response'

local app = require 'app'

local describe, it, assert = describe, it, assert

describe('app hello', function()
	it('responds with hello', function()
    local w, req = writer.new(), request.new()
    app(w, req)
    assert.same({'Hello World!\n'}, w.buffer)
  end)
end)

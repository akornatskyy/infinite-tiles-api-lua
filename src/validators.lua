local validator = require 'validation.validator'
local required = require 'validation.rules.required'
local range = require 'validation.rules.range'

local rules = require 'rules'

local allowed_keys = rules.allowed_keys

return {
  tiles = validator.new {
    __ERROR__ = {allowed_keys {'t', 'area', 'ref', 'coords'}},
    area = {required},
    ref = {range {min = 0, max = 127}}
  }
}

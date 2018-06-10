local validator = require 'validation.validator'
local length = require 'validation.rules.length'
local required = require 'validation.rules.required'
local range = require 'validation.rules.range'

local rules = require 'rules'

local allowed_keys = rules.allowed_keys
local number = rules.number

local coordinate_rule = {number, range{-100, 100}}

return {
  tiles = validator.new {
    __ERROR__ = {allowed_keys {'t', 'area', 'ref', 'coords'}},
    area = {required},
    ref = {range {min = 0, max = 127}}
  },
  place = validator.new {
    __ERROR__ = {allowed_keys {'t', 'x', 'y'}},
    x = coordinate_rule,
    y = coordinate_rule
  },
  move = validator.new {
    __ERROR__ = {allowed_keys {'t', 'id', 'x', 'y'}},
    id = {required, length {min = 8, max = 8}},
    x = coordinate_rule,
    y = coordinate_rule
  }
}

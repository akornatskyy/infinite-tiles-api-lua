local validator = require 'validation.validator'
local length = require 'validation.rules.length'
local range = require 'validation.rules.range'
local required = require 'validation.rules.required'

local rules = require 'rules'

local allowed_fields = rules.allowed_fields
local integer = rules.integer
local number = rules.number

local coordinate_rule = {integer, range {-100, 100}}

return {
  ping = validator.new {
    __ERROR__ = {allowed_fields {'t', 'time'}},
    time = {number, range {min = 1530902228}}
  },
  tiles = validator.new {
    __ERROR__ = {allowed_fields {'t', 'area', 'ref', 'coords'}},
    area = {required},
    ref = {range {min = 0, max = 127}}
  },
  place = validator.new {
    __ERROR__ = {allowed_fields {'t', 'x', 'y'}},
    x = coordinate_rule,
    y = coordinate_rule
  },
  move = validator.new {
    __ERROR__ = {allowed_fields {'t', 'id', 'x', 'y'}},
    id = {required, length {min = 8, max = 8}},
    x = coordinate_rule,
    y = coordinate_rule
  }
}

local fields = require 'validation.rules.fields'
local items = require 'validation.rules.items'
local length = require 'validation.rules.length'
local range = require 'validation.rules.range'
local required = require 'validation.rules.required'
local rule = require 'validation.rules.rule'
local typeof = require 'validation.rules.typeof'
local optional = require 'validation.rules.optional'
local validator = require 'validation.validator'

local rules = require 'rules'

local coordinate_rules = {required, typeof 'integer', range {-100, 100}}

return {
  ping = validator.new {
    __ERROR__ = {fields {'t', 'time'}},
    time = {required, typeof 'number', range {min = 1530902228}}
  },
  tiles = validator.new {
    __ERROR__ = {fields {'t', 'area', 'ref', 'coords'}},
    area = {
      required,
      typeof 'table',
      items {typeof 'integer'},
      rule(rules.area)
    },
    ref = {optional {typeof 'integer', range {min = 0, max = 127}}},
    coords = {
      optional {
        typeof 'table',
        rule(rules.coords),
        items {typeof 'integer', range {min = 0, max = 23}}
      }
    }
  },
  place = validator.new {
    __ERROR__ = {fields {'t', 'x', 'y'}},
    x = coordinate_rules,
    y = coordinate_rules
  },
  move = validator.new {
    __ERROR__ = {fields {'t', 'id', 'x', 'y'}},
    id = {required, typeof 'string', length {min = 8, max = 8}},
    x = coordinate_rules,
    y = coordinate_rules
  }
}


local helpers = require("test.unit.helpers")
local eval_helpers = require('test.unit.eval.helpers')
local api_helpers = require('test.unit.api.helpers')
local func_helper = require('test.functional.helpers')

local lua2typvalt = eval_helpers.lua2typvalt
local typvalt2lua = eval_helpers.typvalt2lua
local typvalt = eval_helpers.typvalt


local to_cstr = helpers.to_cstr
local get_str = helpers.ffi.string
local eq      = helpers.eq
local NULL    = helpers.NULL

local eval = helpers.cimport("./src/nvim/eval.h")
local api = helpers.cimport("./src/nvim/api/private/helpers.h")
local nvim = helpers.cimport("./src/nvim/api/vim.h")

describe('map related functions', function()
  local pretty_print = function(t)
    print('printing table...')
    for k, v in pairs(t) do
      print(k, v)
    end
    print('...done')
  end

  -- Name, mode, abbr, dict
  local result = typvalt()
  func_helper.request('nvim_command', 'inoremap asdfasdf asdf')
  eval.get_maparg(lua2typvalt({ 'asdf', 'i', false, true }), result, true)
  local result = typvalt2lua(result)

  print(result)
  pretty_print(result)

end)

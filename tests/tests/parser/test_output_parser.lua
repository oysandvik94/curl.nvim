local new_set = MiniTest.new_set

local output_parser = require("curl.output_parser")
local test_util = require("tests.testing_util")

local child = MiniTest.new_child_neovim()
local T = new_set({
  hooks = {
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ "-u", "scripts/minimal_init.lua" })
      -- Load tested plugin
      child.lua([[M = require('curl').setup({ open_with = "split"})]])
    end,
    after_case = function()
      api.close_curl_tab(true)
    end,
  },
})

T["Parser"] = new_set()
T["Parser"]["is parsed json"] = function()
  local output = output_parser.parse_curl_output('{ "test": 2 }')

  local expected = {
    "{",
    '  "test": 2',
    "}",
  }

  test_util.assert_table_equals(expected, output)
end

T["Parser"]["is parsed from list"] = function()
  local output = output_parser.parse_curl_output('[{ "test": 2}, { "test": 3}]')

  local expected = {
    "[",
    "  {",
    '    "test": 2',
    "  },",
    "  {",
    '    "test": 3',
    "  }",
    "]",
  }

  test_util.assert_table_equals(expected, output)
end

T["Parser"]["can parse headers"] = function()
  local expected = {
    "HTTP/2 200",
    "date: Sat, 29 Jun 2024 15:36:55 GMT",
    "content-type: application/json; charset=utf-8",
    "content-length: 83",
    "",
    "{",
    '  "userId": 1,',
    '  "id": 1,',
    '  "title": "dele ctus aut autem",',
    '  "completed": false',
    "}",
  }

  local input =
    'HTTP/2 200 \r date: Sat, 29 Jun 2024 15:36:55 GMT\r content-type: application/json; charset=utf-8\r content-length: 83\r \r {"userId": 1,   "id": 1,   "title": "dele ctus aut autem",   "completed": false }'

  local output = output_parser.parse_curl_output(input)

  test_util.assert_table_equals(expected, output)
end

T["Parser"]["can parse list after headers"] = function()
  local expected = {
    "HTTP/2 200",
    "date: Sat, 29 Jun 2024 15:36:55 GMT",
    "",
    "[",
    "  {",
    '    "test": 3',
    "  }",
    "]",
  }

  local input = 'HTTP/2 200 \r date: Sat, 29 Jun 2024 15:36:55 GMT\r \r [{"test": 3}]'

  local output = output_parser.parse_curl_output(input)

  test_util.assert_table_equals(expected, output)
end

T["Parser"]["can parse large command"] = function()
  local Path = require("plenary.path")
  local curl_output = Path:new("tests/tests/parser/big.json"):read()

  local parsed_output = output_parser.parse_curl_output(curl_output)

  assert(#parsed_output == 12657)
end

return T

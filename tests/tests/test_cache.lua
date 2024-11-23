local new_set = MiniTest.new_set
local api = require("curl.api")
local cache = require("curl.cache")
local test_util = require("tests.testing_util")

local T = new_set({
  hooks = {
    after_case = function()
      api.close_curl_tab(true)
    end,
  },
})

T["Cache"] = new_set()
T["Cache"]["can retrieve scoped collections"] = function()
  local first_coll = "scopedbar"
  api.open_scoped_collection(first_coll)
  vim.cmd("silent w")

  local second_coll = "scopedfoo"
  api.open_scoped_collection(second_coll)
  vim.cmd("silent w")

  local collections = cache.get_collections(false)

  MiniTest.expect.equality(#collections > 0, true)

  local expected_list = {
    "scopedbar",
    "scopedfoo",
  }

  test_util.assert_table_equals(expected_list, collections)
end

T["Cache"]["does not retrive global scopes when searching scoped"] = function()
  local first_coll = "scopedbar"
  api.open_scoped_collection(first_coll)
  vim.cmd("silent w")

  local second_coll = "scopedfoo"
  api.open_scoped_collection(second_coll)
  vim.cmd("silent w")

  local collections = cache.get_collections(true)

  local expected_list = {}

  test_util.assert_table_equals(expected_list, collections)
end

T["Cache"]["can retrieve global collections"] = function()
  local first_coll = "globalbar"
  api.open_global_collection(first_coll)
  vim.cmd("silent w")

  local second_coll = "globalfoo"
  api.open_global_collection(second_coll)
  vim.cmd("silent w")

  local collections = cache.get_collections(true)

  MiniTest.expect.equality(#collections > 0, true)

  local expected_list = {
    "globalbar",
    "globalfoo",
  }

  test_util.assert_table_equals(expected_list, collections)
end

return T

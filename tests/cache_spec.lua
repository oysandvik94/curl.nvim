local api = require("curl.api")
local cache = require("curl.cache")
local buffers = require("curl.buffers")
local test_util = require("tests.test_util")

after_each(function()
	api.close_curl_tab(true)
end)

describe("Cache", function()
	it("can retrieve scoped collections", function()
		local first_coll = "scopedbar"
		api.open_scoped_collection(first_coll)
		vim.cmd("silent w")

		local second_coll = "scopedfoo"
		api.open_scoped_collection(second_coll)
		vim.cmd("silent w")

		local collections = cache.get_collections(false)

		assert(#collections > 0, "Should find some collection")

		local expected_list = {
			"scopedbar",
			"scopedfoo",
		}

		test_util.assert_table_equals(expected_list, collections)
	end)

	it("does not retrive global scopes when searching scoped", function()
		local first_coll = "scopedbar"
		api.open_scoped_collection(first_coll)
		vim.cmd("silent w")

		local second_coll = "scopedfoo"
		api.open_scoped_collection(second_coll)
		vim.cmd("silent w")

		local collections = cache.get_collections(true)

		local expected_list = {}

		test_util.assert_table_equals(expected_list, collections)
	end)

	it("can retrieve global collections", function()
		local first_coll = "globalbar"
		api.open_global_collection(first_coll)
		vim.cmd("silent w")

		local second_coll = "globalfoo"
		api.open_global_collection(second_coll)
		vim.cmd("silent w")

		local collections = cache.get_collections(true)

		assert(#collections > 0, "Should find some collection")

		local expected_list = {
			"globalbar",
			"globalfoo",
		}

		test_util.assert_table_equals(expected_list, collections)
	end)
end)

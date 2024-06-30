local curl = require("curl")
local config = require("lua.curl.config")
local test_util = require("tests.test_util")

describe("Config", function()
	it("has default mapping", function()
		local default_mapping = config.get("mappings")["execute_curl"]

		test_util.assert_equals("<CR>", default_mapping)
	end)

	it("can set curl keymap", function()
		curl.setup({ mappings = { execute_curl = "<C-r>" } })

		local curl_mapping = config.get("mappings")["execute_curl"]

		test_util.assert_equals("<C-r>", curl_mapping)
	end)
end)

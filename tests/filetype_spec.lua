local api = require("curl.api")
local test_util = require("tests.test_util")

after_each(function()
	api.close_curl_tab(true)
end)

describe("Curl files", function()
	it("can execute and automatically open buffer", function()
		vim.cmd("e test_hehe.curl")

		local keymap = vim.api.nvim_buf_get_keymap(0, "n")[1] ---@type vim.api.keyset.keymap

		test_util.assert_equals("<CR>", keymap.lhs, "Should have bind to enter")
		test_util.assert_equals(
			"<Cmd>lua require('curl.api').execute_curl()<CR>",
			keymap.rhs,
			"Should bind curl execute"
		)
	end)
end)

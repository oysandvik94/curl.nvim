local api = require("curl.api")
local buffers = require("lua.curl.buffers")
local test_util = require("tests.test_util")

describe("Api", function()
	it("should open correct tabs", function()
		api.open_curl_tab()

		local tab = vim.api.nvim_get_current_tabpage()
		local windows = vim.api.nvim_tabpage_list_wins(tab)
		assert(#windows == 2, "Tab should open with two buffers")

		local left_buffer = vim.api.nvim_win_get_buf(windows[1])
		local left_name = vim.api.nvim_buf_get_name(left_buffer):match("Curl Command$")
		assert(left_name ~= nil, "Name for left buffer was not set")

		local right_buffer = vim.api.nvim_win_get_buf(windows[2])
		local right_name = vim.api.nvim_buf_get_name(right_buffer):match("Curl Output$")
		assert(right_name ~= nil, "Name for right buffer was not set")
	end)
end)

describe("Buffer", function()
	it("should output to right buffer", function()
		api.open_curl_tab()

		local lines = {
			"1",
			"2",
			"3",
		}

		buffers.set_output_buffer_content(lines)

		vim.cmd("wincmd l")
		local right_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

		test_util.assert_table_equals(lines, right_content)
	end)
end)

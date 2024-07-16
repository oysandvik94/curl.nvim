local api = require("curl.api")
local buffers = require("curl.buffers")
local test_util = require("tests.test_util")

describe("Api", function()
	after_each(function()
		api.close_curl_tab(true)
	end)

	it("should open correct tabs", function()
		api.open_curl_tab()

		local tab = vim.api.nvim_get_current_tabpage()
		local windows = vim.api.nvim_tabpage_list_wins(tab)
		assert(#windows == 2, "Tab should open with two buffers")

		local left_buffer = vim.api.nvim_win_get_buf(windows[1])
		assert(left_buffer > 0, "Name for left buffer was not set")

		local right_buffer = vim.api.nvim_win_get_buf(windows[2])
		assert(right_buffer > 0, "Name for right buffer was not set")
	end)

	it("should not open multiple tabs", function()
		api.open_curl_tab()
		local tabs_before = vim.api.nvim_list_tabpages()
		api.open_curl_tab()
		local tabs_after = vim.api.nvim_list_tabpages()

		assert(#tabs_before == #tabs_after, "Should not open new tab")
	end)

	it("should go to tab when called twice", function()
		api.open_curl_tab()
		vim.cmd("tabnew")

		local tabs_before = vim.api.nvim_list_tabpages()
		api.open_curl_tab()
		local tabs_after = vim.api.nvim_list_tabpages()
		assert(#tabs_before == #tabs_after, "Should go to tab instead of opening new one")

		local current_tab = vim.api.nvim_get_current_tabpage()
		local windows = vim.api.nvim_tabpage_list_wins(current_tab)
		local left_buf = vim.api.nvim_win_get_buf(windows[1])
		test_util.assert_equals(left_buf, COMMAND_BUF_ID, "Left buf in curl tab should be active")
	end)

	it("should close correct tab", function()
		api.open_curl_tab()
		api.close_curl_tab()

		local current_tab = vim.api.nvim_get_current_tabpage()
		local windows = vim.api.nvim_tabpage_list_wins(current_tab)
		local left_buf = vim.api.nvim_win_get_buf(windows[1])
		local left_name = vim.api.nvim_buf_get_name(left_buf):match("Curl Command$")
		assert(left_name == nil, "Left buf in curl tab should be closed")
	end)

	it("should close even if command was opened twice", function()
		api.open_scoped_collection("foo")
		api.open_scoped_collection("test")
		api.close_curl_tab()
	end)

	it("calling close twice should not error", function()
		api.open_curl_tab()
		api.close_curl_tab()
		api.close_curl_tab()
	end)

	it("calling execute twice does not open buffer twice", function()
		local mock_pre = vim.fn.jobstart
		vim.fn.jobstart = function() end
		api.open_curl_tab()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "curl test.com" })
		api.execute_curl()
		local before_buffer_count = #vim.api.nvim_list_wins()
		api.execute_curl()
		local after_buffer_count = #vim.api.nvim_list_wins()
		test_util.assert_equals(
			before_buffer_count,
			after_buffer_count,
			"Executing curl twice should not open output buffer twice"
		)
		vim.fn.jobstart = mock_pre
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

		vim.cmd("wincmd l")
		buffers.set_output_buffer_content(lines, 0)

		local right_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

		test_util.assert_table_equals(lines, right_content)
	end)

	it("multiple opens should switch buffer", function()
		api.close_curl_tab()
		local inital_tabs = vim.api.nvim_list_tabpages()
		api.open_curl_tab()
		local first_tabs = vim.api.nvim_list_tabpages()
		test_util.assert_equals(#inital_tabs + 1, #first_tabs, "Should only have opened one extra tab on first open")

		local pre_buf_count = #vim.api.nvim_list_bufs()
		local second_buf_id = COMMAND_BUF_ID
		api.open_curl_tab()
		local post_buf_count = #vim.api.nvim_list_bufs()
		test_util.assert_equals(pre_buf_count, post_buf_count, "Buf should stay the same")

		api.open_global_tab()
		local third_buf_id = COMMAND_BUF_ID
		assert(second_buf_id ~= third_buf_id, "Buffer should change")
		assert(vim.tbl_contains(vim.api.nvim_list_bufs(), second_buf_id) == false, "cwd buffer should be closed")

		test_util.assert_equals(post_buf_count, #vim.api.nvim_list_bufs(), "Should not open more buffers, just replace")

		api.open_scoped_collection("test")
		local fourth_buf_id = COMMAND_BUF_ID
		assert(third_buf_id ~= fourth_buf_id, "Buffer should change")
		assert(vim.tbl_contains(vim.api.nvim_list_bufs(), third_buf_id) == false, "global buffer should be closed")

		test_util.assert_equals(post_buf_count, #vim.api.nvim_list_bufs(), "Should not open more buffers, just replace")

		local tabs = vim.api.nvim_list_tabpages()
		test_util.assert_equals(#inital_tabs + 1, #tabs, "Should only have opened one extra tab")
	end)
end)

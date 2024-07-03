local api = require("curl.api")
local buffers = require("curl.buffers")
local test_util = require("tests.test_util")

after_each(function()
	api.close_curl_tab(true)
end)

describe("Api", function()
	it("can curl something", function()
		local curl_command = "curl localhost:8000"

		local mocked_jobstart = function(command, callback)
			test_util.assert_equals(curl_command .. " -sSL", command)

			buffers.set_output_buffer_content({ "test" }, OUTPUT_BUF_ID)
		end
		vim.fn.jobstart = mocked_jobstart

		api.open_curl_tab()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { curl_command })

		api.execute_curl()

		vim.cmd("wincmd l")
		local output = vim.api.nvim_buf_get_lines(OUTPUT_BUF_ID, 0, -1, false)

		assert(output[1] == "test", "Curl should have produced a result")
	end)

	it("can open custom buffer", function()
		api.open_custom_tab("sauron")

		local bufname = vim.api.nvim_buf_get_name(0)
		assert(bufname:find("sauron") ~= nil, "Custom buffer should be closed")

		api.close_curl_tab()
		local new_bufname = vim.api.nvim_buf_get_name(0)
		assert(new_bufname:find("sauron") == nil, "Buffer should be closed")
	end)

	it("can open global buffer", function()
		api.open_global_tab()

		local bufname = vim.api.nvim_buf_get_name(0)
		assert(bufname:find("global") ~= nil, "Custom buffer should be closed")

		api.close_curl_tab()
		local new_bufname = vim.api.nvim_buf_get_name(0)
		assert(new_bufname:find("global") == nil, "Buffer should be closed")
	end)
end)

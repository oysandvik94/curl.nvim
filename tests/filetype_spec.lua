local api = require("curl.api")
local buffers = require("curl.buffers")
local test_util = require("tests.test_util")

after_each(function()
	api.close_curl_tab(true)
end)

describe("Curl files", function()
	it("can execute and automatically open buffer", function()
		local curl_command = "curl localhost:8000"

		local mocked_jobstart = function(command, callback)
			test_util.assert_equals(curl_command .. " -sSL", command)
		end
		local mock_pre = vim.fn.jobstart
		vim.fn.jobstart = mocked_jobstart

		vim.cmd("e test.curl")
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { curl_command })

		api.execute_curl()

		assert(OUTPUT_BUF_ID ~= -1, "Curl should have produced a result")
		vim.fn.jobstart = mock_pre
	end)
end)

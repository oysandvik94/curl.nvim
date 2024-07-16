local curl = require("curl")
local config = require("curl.config")
local test_util = require("tests.test_util")
local api = require("curl.api")

after_each(function()
	api.close_curl_tab(true)
end)

describe("Config", function()
	it("has default mapping", function()
		local default_mapping = config.get("mappings")["execute_curl"]

		test_util.assert_equals("<CR>", default_mapping)
	end)

	it("can set curl keymap", function()
		curl.setup({ mappings = { execute_curl = "<C-r>" } })

		local curl_mapping = config.get("mappings")["execute_curl"]

		test_util.assert_equals("<C-r>", curl_mapping)
		curl.setup({})
	end)

	it("can set default flags", function()
		curl.setup({ default_flags = { "-i" } })
		test_util.assert_equals(config.get("default_flags")[1], "-i", "Default flag config should be set")

		local curl_command = "curl localhost:8000"

		local mocked_jobstart = function(command, _)
			test_util.assert_equals(curl_command .. " -sSL -i", command, "Default flag should be added")
		end
		local mock_pre = vim.fn.jobstart
		vim.fn.jobstart = mocked_jobstart

		api.open_curl_tab()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { curl_command })
		api.execute_curl()
		vim.fn.jobstart = mock_pre
		curl.setup({})
	end)

	it("can set alternative curl alias from config", function()
		local curl_alias = "/my/cool/curl"
		curl.setup({ curl_binary = curl_alias })
		test_util.assert_equals(config.get("curl_binary"), curl_alias, "Curl alias should be set")

		local curl_command = "curl localhost:8000"

		local mocked_jobstart = function(command, _)
			test_util.assert_equals(curl_alias .. " localhost:8000 -sSL", command, "Curl alias should be used")
		end
		local mock_pre = vim.fn.jobstart
		vim.fn.jobstart = mocked_jobstart

		api.open_curl_tab()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { curl_command })
		api.execute_curl()
		vim.fn.jobstart = mock_pre
		curl.setup({})
	end)

	it("can set alternative curl alias in runtime", function()
		local curl_alias = "/my/cool/curl"
		api.set_curl_binary(curl_alias)
		test_util.assert_equals(config.get("curl_binary"), curl_alias, "Curl alias should be set")

		local curl_command = "curl localhost:8000"

		local mocked_jobstart = function(command, _)
			test_util.assert_equals(curl_alias .. " localhost:8000 -sSL", command, "Curl alias should be used")
		end
		local mock_pre = vim.fn.jobstart
		vim.fn.jobstart = mocked_jobstart

		api.open_curl_tab()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { curl_command })
		api.execute_curl()
		vim.fn.jobstart = mock_pre
	end)
end)

local curl = require("curl")
local config = require("curl.config")
local test_util = require("tests.test_util")
local api = require("curl.api")

after_each(function()
	api.close_curl_tab(true)
end)

describe("Split option opens split instead of tab", function()
	local function test_split(open_func, arg)
		local tabpages_before = #vim.api.nvim_list_tabpages()
		curl.setup({ open_with = "split" })
		open_func(arg)
		local tabpages_after = #vim.api.nvim_list_tabpages()

		test_util.assert_equals(tabpages_before, tabpages_after, "No new tab should be opened")

		local buf_name = vim.api.nvim_buf_get_name(0)
		local is_curl_file = buf_name:match("%.curl$") ~= nil
		test_util.assert_equals(is_curl_file, true, "Should open a curl file")

		local windows_open = #vim.api.nvim_tabpage_list_wins(0)
		test_util.assert_equals(windows_open, 2, "Should split window in 2")
	end

	it("when using collection scoped", function()
		test_split(api.open_curl_tab)
	end)

	it("when using global scoped", function()
		test_split(api.open_global_tab)
	end)

	it("when using global collection", function()
		test_split(api.open_global_collection, "foo")
	end)

	it("when using scoped collection", function()
		test_split(api.open_scoped_collection, "bar")
	end)
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

    -- stylua: ignore
		local mocked_jobstart = function(command, _)
			test_util.assert_equals(curl_command .. " -sSL -i", command[#command], "Default flag should be added")
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

    -- stylua: ignore
		local mocked_jobstart = function(command, _)
			test_util.assert_equals(curl_alias .. " localhost:8000 -sSL", command[#command], "Curl alias should be used")
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

    -- stylua: ignore
		local mocked_jobstart = function(command, _)
			test_util.assert_equals(curl_alias .. " localhost:8000 -sSL", command[#command], "Curl alias should be used")
		end
		local mock_pre = vim.fn.jobstart
		vim.fn.jobstart = mocked_jobstart

		api.open_curl_tab()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { curl_command })
		api.execute_curl()
		vim.fn.jobstart = mock_pre
	end)
end)

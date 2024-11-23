local new_set = MiniTest.new_set

local curl = require("curl")
local config = require("curl.config")
local test_util = require("tests.testing_util")
local api = require("curl.api")

local child = MiniTest.new_child_neovim()
local T = new_set({
  hooks = {
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ "-u", "scripts/minimal_init.lua" })
      -- Load tested plugin
      child.lua([[M = require('curl').setup({ open_with = "split"})]])
    end,
    after_case = function()
      api.close_curl_tab(true)
    end,
  },
})

local function test_split(open_func)
  local tabpages_before = #child.api.nvim_list_tabpages()
  child.lua(open_func)
  local tabpages_after = #child.api.nvim_list_tabpages()

  test_util.assert_equals(tabpages_before, tabpages_after, "No new tab should be opened")

  local buf_name = child.api.nvim_buf_get_name(0)
  local is_curl_file = buf_name:match("%.curl$") ~= nil
  test_util.assert_equals(is_curl_file, true, "Should open a curl file")

  local windows_open = #child.api.nvim_tabpage_list_wins(0)
  test_util.assert_equals(windows_open, 2, "Should split window in 2")
end
T["Config"] = new_set()
T["Config"]["Split when using collection scoped"] = function()
  test_split("require('curl').open_curl_tab()")
end

T["Config"]["Split when using global scoped"] = function()
  test_split([[require("curl").open_global_tab()]])
end

T["Config"]["Split when using global collection"] = function()
  test_split([[require("curl").open_global_collection("foo")]])
end

T["Config"]["Split when using scoped collection"] = function()
  test_split([[require("curl").open_scoped_collection("bar")]])
end

T["Config"]["has default mapping"] = function()
  local default_mapping = config.get("mappings")["execute_curl"]

  test_util.assert_equals("<CR>", default_mapping)
end

T["Config"]["can set curl keymap"] = function()
  curl.setup({ mappings = { execute_curl = "<C-r>" } })

  local curl_mapping = config.get("mappings")["execute_curl"]

  test_util.assert_equals("<C-r>", curl_mapping)
  curl.setup({})
end

T["Config"]["can set default flags"] = function()
  child.lua([[require("curl").setup({ default_flags = { "-i" } })]])

  -- stylua: ignore
  local mocked_jobstart = function(command, _)
    MiniTest.expect.equality("curl localhost:8000" .. " -sSL -i" , command[#command])
  end
  local mock_pre = child.fn.jobstart
  child.fn.jobstart = mocked_jobstart

  child.lua([[require("curl").open_curl_tab()]])
  local curl_command = "curl localhost:8000"
  child.api.nvim_buf_set_lines(0, 0, -1, false, { curl_command })
  child.lua([[require("curl").execute_curl()]])
  child.fn.jobstart = mock_pre
  curl.setup({})
end

T["Config"]["can set alternative curl alias from config"] = function()
  child.lua([[require("curl").setup({ curl_binary = "/my/cool/curl" })]])

  local curl_command = "curl localhost:8000"

  -- stylua: ignore
  local mocked_jobstart = function(command, _)
    MiniTest.expect.equality("/my/cool/curl" .. " localhost:8000 -sSL", command[#command])
  end
  local mock_pre = child.fn.jobstart
  child.fn.jobstart = mocked_jobstart

  child.lua([[require("curl").open_curl_tab()]])
  child.api.nvim_buf_set_lines(0, 0, -1, false, { curl_command })
  child.lua([[require("curl").execute_curl()]])
  child.fn.jobstart = mock_pre
end

T["Config"]["can set alternative curl alias in runtime"] = function()
  child.lua([[require("curl").set_curl_binary("/my/cool/curl")]])

  local curl_command = "curl localhost:8000"

   -- stylua: ignore
  local mocked_jobstart = function(command, _)
    MiniTest.expect.equality("/my/cool/curl" .. " localhost:8000 -sSL", command[#command])
  end
  local mock_pre = child.fn.jobstart
  child.fn.jobstart = mocked_jobstart

  child.lua([[require("curl").open_curl_tab()]])
  child.api.nvim_buf_set_lines(0, 0, -1, false, { curl_command })
  child.lua([[require("curl").execute_curl()]])
  child.fn.jobstart = mock_pre
end

return T

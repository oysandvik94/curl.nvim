local new_set = MiniTest.new_set
local api = require("curl.api")
local buffers = require("curl.buffers")
local test_util = require("tests.testing_util")

local child = MiniTest.new_child_neovim()
local T = new_set({
  hooks = {
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ "-u", "scripts/minimal_init.lua" })
      -- Load tested plugin
      child.lua([[M = require('curl').setup({})]])
    end,
    after_case = function()
      api.close_curl_tab(true)
    end,
  },
})
T["Buffer"] = new_set()

T["Buffer"]["should open correct tabs"] = function()
  child.lua([[
    require("curl").open_curl_tab()
    ]])

  local tab = child.api.nvim_get_current_tabpage()
  local windows = child.api.nvim_tabpage_list_wins(tab)
  MiniTest.expect.equality(#windows, 1)

  local left_buffer = child.api.nvim_win_get_buf(windows[1])
  assert(left_buffer > 0, "Name for left buffer was not set")
end

T["Buffer"]["should not open multiple tabs"] = function()
  child.lua([[
    require("curl").open_curl_tab()
    ]])
  local tabs_before = child.api.nvim_list_tabpages()
  child.lua([[
    require("curl").open_curl_tab()
    ]])
  local tabs_after = child.api.nvim_list_tabpages()

  assert(#tabs_before == #tabs_after, "Should not open new tab")
end

T["Buffer"]["should go to tab when called twice"] = function()
  child.lua([[
    require("curl").open_curl_tab()
    ]])
  child.cmd("tabnew")

  local tabs_before = child.api.nvim_list_tabpages()
  child.lua([[
    require("curl").open_curl_tab()
    ]])
  local tabs_after = child.api.nvim_list_tabpages()
  assert(#tabs_before == #tabs_after, "Should go to tab instead of opening new one")

  local current_tab = child.api.nvim_get_current_tabpage()
  local windows = child.api.nvim_tabpage_list_wins(current_tab)
  local left_buf = child.api.nvim_win_get_buf(windows[1])
  test_util.assert_equals(
    left_buf,
    child.lua_func(function()
      return COMMAND_BUF_ID
    end),
    "Left buf in curl tab should be active"
  )
end

T["Buffer"]["should close correct tab"] = function()
  child.lua([[
    require("curl").open_curl_tab()
    ]])
  child.lua([[
    require("curl").close_curl_tab()
    ]])

  local current_tab = child.api.nvim_get_current_tabpage()
  local windows = child.api.nvim_tabpage_list_wins(current_tab)
  local left_buf = child.api.nvim_win_get_buf(windows[1])
  local left_name = child.api.nvim_buf_get_name(left_buf):match("Curl Command$")
  assert(left_name == nil, "Left buf in curl tab should be closed")
end

T["Buffer"]["should close even if command was opened twice"] = function()
  child.lua([[
    require("curl").open_scoped_collection("foo")
    ]])
  child.lua([[
    require("curl").open_scoped_collection("test")
    ]])
  child.lua([[
    require("curl").close_curl_tab()
    ]])
end

T["Buffer"]["calling close twice should not error"] = function()
  child.lua([[
     require("curl").open_curl_tab()
     ]])
  child.lua([[
     require("curl").close_curl_tab()
     ]])
  child.lua([[
     require("curl").close_curl_tab()
     ]])
end

T["Buffer"]["calling execute twice does not open buffer twice"] = function()
  local mock_pre = vim.fn.jobstart
  vim.fn.jobstart = function() end
  child.lua([[
     require("curl").open_curl_tab()
     ]])
  child.api.nvim_buf_set_lines(0, 0, -1, false, { "curl test.com" })
  child.lua([[
     require("curl").execute_curl()
     ]])
  local before_buffer_count = #child.api.nvim_list_wins()
  child.lua([[
     require("curl").execute_curl()
     ]])
  local after_buffer_count = #child.api.nvim_list_wins()
  test_util.assert_equals(
    before_buffer_count,
    after_buffer_count,
    "Executing curl twice should not open output buffer twice"
  )
  vim.fn.jobstart = mock_pre
end

T["Buffer"]["should output to right buffer"] = function()
  child.lua([[
     require("curl").open_curl_tab()
     ]])

  local lines = {
    "1",
    "2",
    "3",
  }

  local cur_win = vim.api.nvim_get_current_win()
  buffers.set_output_buffer_content(cur_win, lines)

  vim.cmd("wincmd l")
  local right_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  test_util.assert_table_equals(lines, right_content)
end

T["Buffer"]["multiple opens should switch buffer"] = function()
  child.lua([[
     require("curl").close_curl_tab()
     ]])
  local inital_tabs = child.api.nvim_list_tabpages()
  child.lua([[
     require("curl").open_curl_tab()
     ]])
  local first_tabs = child.api.nvim_list_tabpages()
  test_util.assert_equals(#inital_tabs + 1, #first_tabs, "Should only have opened one extra tab on first open")

  local second_buf_id = child.lua_func(function()
    return COMMAND_BUF_ID
  end)
  child.lua([[
     require("curl").open_curl_tab()
     ]])
  local post_buf_count = #child.api.nvim_list_bufs()

  child.lua([[
     require("curl").open_global_tab()
     ]])
  local third_buf_id = child.lua_func(function()
    return COMMAND_BUF_ID
  end)

  assert(second_buf_id ~= third_buf_id, "Buffer should change")

  child.lua([[
     require("curl").open_scoped_collection("test")
     ]])
  local fourth_buf_id = child.lua_func(function()
    return COMMAND_BUF_ID
  end)

  assert(third_buf_id ~= fourth_buf_id, "Buffer should change")

  local tabs = child.api.nvim_list_tabpages()
  test_util.assert_equals(#inital_tabs + 1, #tabs, "Should only have opened one extra tab")
end

T["Buffer"]["output buffer respects horizontal split configuration"] = function()
  -- Override config to use horizontal split for output
  child.lua([[require("curl").setup({ output_split_direction = "horizontal" })]])
  child.lua([[require("curl").open_curl_tab()]])

  local lines = { "test", "output" }
  -- Get the actual current window ID from the child process
  local cur_win = child.api.nvim_get_current_win()
  child.lua(string.format([[require("curl.buffers").set_output_buffer_content(%d, {"test", "output"})]], cur_win))

  -- Check that we have 2 windows after opening output
  local windows = child.api.nvim_tabpage_list_wins(0)
  test_util.assert_equals(2, #windows, "Should have 2 windows after opening output")

  -- Verify the config was actually set
  local output_split_direction = child.lua_get([[require("curl.config").get("output_split_direction")]])
  test_util.assert_equals("horizontal", output_split_direction)
end

return T

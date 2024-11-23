local new_set = MiniTest.new_set
local api = require("curl.api")
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

T["Curl files"] = new_set()
T["Curl files"]["can execute and automatically open buffer"] = function()
  child.cmd("e test_hehe.curl")
  local keymap = child.api.nvim_buf_get_keymap(0, "n")[1]
  test_util.assert_equals("<CR>", keymap.lhs, "Should have bind to enter")
  test_util.assert_equals("<Cmd>lua require('curl.api').execute_curl()<CR>", keymap.rhs, "Should bind curl execute")
end

return T

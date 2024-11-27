local new_set = MiniTest.new_set
local tokenizer = require("curl.tokenizer")

local child = MiniTest.new_child_neovim()
local T = new_set({
  hooks = {
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ "-u", "scripts/minimal_init.lua" })
      -- Load tested plugin
      child.lua([[M = require('curl').setup({ })]])
    end,
    after_case = function()
      api.close_curl_tab(true)
    end,
  },
})

T["Tokenizer"] = new_set()
T["Tokenizer"]["tokenize input"] = function()
  local test = "const test = curl -v https://jsonplaceholder.typicode.com/todos/1"

  local result = tokenizer.tokenize(test)

  MiniTest.expect.equality(result.command, "curl -v https://jsonplaceholder.typicode.com/todos/1")
  MiniTest.expect.equality(result.variable, "test")
end

return T

vim.bo.syntax = "sh"
vim.bo.commentstring = "# %s"

local config = require("curl.config")
local execute_mapping = config.get("mappings")["execute_curl"]
vim.api.nvim_buf_set_keymap(
	0,
	"n",
	execute_mapping,
	"<cmd>lua require('curl.api').execute_curl()<CR>",
	{ noremap = true, silent = true }
)

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
	command = "silent w",
	buffer = 0,
	nested = true,
})

vim.treesitter.language.register("bash", "curl")
local bash_lang_installed, _ = pcall(vim.treesitter.get_parser, 0, "bash")
if bash_lang_installed then
	require("curl.treesitter").add_treesitter_highlighting()
	return
end

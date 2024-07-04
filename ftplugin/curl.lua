vim.bo.syntax = "sh"
vim.bo.commentstring = "# %s"

vim.treesitter.language.register("bash", "curl")

-- Custom highlights for curl-specific elements
local query = vim.treesitter.query.parse(
	"bash",
	[[
      ;; Highlight the 'curl' command
      ((command_name) @curl (#eq? @curl "curl"))

      ;; Highlight curl options
      ((word) @curl_option (#match? @curl_option "^-"))

      ;; Highlight HTTP methods
      ((word) @http_method (#match? @http_method "^(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS|TRACE|CONNECT)$"))

      ;; Highlight URLs
      ((word) @url (#match? @url "^https?://"))
    ]]
)

local bufnr = 0
local parser = vim.treesitter.get_parser(bufnr, "bash")
local tree = parser:parse()[1]
local root = tree:root()

for id, node in query:iter_captures(root, bufnr, 0, -1) do
	local name = query.captures[id]
	local start_row, start_col, end_row, end_col = node:range()

	if name == "curl" then
		vim.api.nvim_buf_add_highlight(bufnr, -1, "CurlKeyword", start_row, start_col, end_col)
	elseif name == "curl_option" or name == "http_method" then
		vim.api.nvim_buf_add_highlight(bufnr, -1, "CurlFunction", start_row, start_col, end_col)
	elseif name == "url" then
		vim.api.nvim_buf_add_highlight(bufnr, -1, "CurlUrl", start_row, start_col, end_col)
	end
end

vim.api.nvim_set_hl(0, "CurlUrl", {
	link = "@text",
})

vim.api.nvim_set_hl(0, "CurlFunction", {
	link = "@function",
})

vim.api.nvim_set_hl(0, "CurlKeyword", {
	link = "@operator",
})

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

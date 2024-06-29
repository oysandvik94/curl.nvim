M = {}
local cache = require("curl.cache")

CURL_COMMAND_BUF_NAME = "Curl Command"
CURL_OUTPUT_BUF_NAME = "Curl Output"

local function get_or_create_buffer(name)
	local buf = vim.fn.bufnr(name .. "$")

	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf, name)
	end

	return buf
end

M.get_or_create_buffer = function(name)
	get_or_create_buffer(name)
end

M.open_curl_tab = function()
	local curl_buffer = get_or_create_buffer(CURL_COMMAND_BUF_NAME)
	vim.api.nvim_set_option_value("filetype", "sh", { buf = curl_buffer })

	local output_buffer = get_or_create_buffer(CURL_OUTPUT_BUF_NAME)
	vim.api.nvim_set_option_value("filetype", "json", { buf = output_buffer })

	vim.cmd("tabnew")
	vim.api.nvim_win_set_buf(0, curl_buffer)

	local cached_commands = cache.load_cached_commands()
	if #cached_commands > 0 then
		vim.api.nvim_buf_set_lines(curl_buffer, 0, -1, false, cached_commands)
	end

	vim.cmd("vsplit")
	vim.cmd("wincmd l")

	vim.api.nvim_win_set_buf(0, output_buffer)

	vim.cmd("wincmd h")
	return curl_buffer
end

M.get_command_buffer_and_pos = function()
	local left_buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(left_buf, 0, -1, false)

	local cursor_pos = vim.api.nvim_win_get_cursor(0)[1]

	return cursor_pos, lines
end

M.set_output_buffer_content = function(content)
	local right_buf = get_or_create_buffer(CURL_OUTPUT_BUF_NAME)

	vim.api.nvim_buf_set_lines(right_buf, 0, -1, false, content)
end

return M

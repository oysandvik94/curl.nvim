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

local function open_curl_tab_if_created()
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		if pcall(function()
			vim.api.nvim_tabpage_get_var(tab, "id")
		end) then
			if vim.api.nvim_tabpage_get_var(tab, "id") == "curl.nvim" then
				vim.api.nvim_set_current_tabpage(tab)
				vim.api.nvim_set_current_win(vim.api.nvim_tabpage_get_win(tab))
				return true
			end
		end
	end

	return false
end

M.open_curl_tab = function()
	if open_curl_tab_if_created() then
		return 0
	end

	local curl_buffer = get_or_create_buffer(CURL_COMMAND_BUF_NAME)
	vim.api.nvim_set_option_value("filetype", "sh", { buf = curl_buffer })

	local output_buffer = get_or_create_buffer(CURL_OUTPUT_BUF_NAME)
	vim.api.nvim_set_option_value("filetype", "json", { buf = output_buffer })

	vim.cmd("tabnew")
	vim.api.nvim_tabpage_set_var(0, "id", "curl.nvim")
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

local close_curl_window = function(buffer)
	local buf = get_or_create_buffer(buffer)
	local winid = vim.fn.bufwinid(buf)
	if winid ~= -1 then
		vim.api.nvim_win_close(winid, true)
	end
end

M.close_curl_tab = function()
	close_curl_window(CURL_COMMAND_BUF_NAME)
	close_curl_window(CURL_OUTPUT_BUF_NAME)
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

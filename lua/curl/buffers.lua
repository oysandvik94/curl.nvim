local M = {}
local cache = require("curl.cache")

OUTPUT_BUF_ID = -1
COMMAND_BUF_ID = -1
CURL_WINDOW_ID = -1
TAB_ID = "curl.nvim.tab"

local close_curl_buffer = function(buffer, force)
	if buffer == -1 then
		return
	end
	vim.api.nvim_buf_delete(buffer, { force = force })
end

local function find_curl_tab_windid()
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		local success, tab_id = pcall(function() ---@type any,integer
			return vim.api.nvim_tabpage_get_var(tab, "id")
		end)

		if success and tab_id == TAB_ID then
			vim.api.nvim_set_current_tabpage(tab)
			local win_id = vim.api.nvim_tabpage_get_win(tab)
			vim.api.nvim_set_current_win(win_id)
			return win_id
		end
	end
end
local function open_curl_tab_if_created()
	local tab_win_id = find_curl_tab_windid()
	if tab_win_id ~= nil then
		return tab_win_id
	end

	vim.cmd("tabnew")
	vim.api.nvim_tabpage_set_var(0, "id", TAB_ID)
	return vim.api.nvim_tabpage_get_win(0)
end

local open_command_buffer = function(command_file)
	local bufnr = vim.fn.bufnr(command_file, false)

	if bufnr == -1 then
		vim.cmd.edit(command_file)
		local new_bufnr = vim.fn.bufnr(command_file, false)

		if COMMAND_BUF_ID ~= new_bufnr then
			close_curl_buffer(COMMAND_BUF_ID, false)
		end

		return new_bufnr
	end

	vim.api.nvim_win_set_buf(CURL_WINDOW_ID, bufnr)

	return bufnr
end

M.open_result_buffer = function()
	local bufnr = vim.fn.bufnr("Curl output", false)

	if bufnr ~= -1 then
		local curl_tab_winid = vim.fn.win_findbuf(bufnr)
		local open_windows = vim.api.nvim_tabpage_list_wins(0)
		if vim.tbl_contains(open_windows, function(v)
				return vim.tbl_contains(curl_tab_winid, v)
			end, { predicate = true }) == false then
			vim.cmd("vert belowright sb" .. bufnr .. " | wincmd p")
		end
		return bufnr
	end

	local new_bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(new_bufnr, "Curl output")
	vim.api.nvim_set_option_value("filetype", "json", { buf = new_bufnr })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = new_bufnr })
	vim.cmd("vert belowright sb" .. new_bufnr .. " | wincmd p")
	OUTPUT_BUF_ID = new_bufnr
	return new_bufnr
end

local setup_curl_tab_for_file = function(filename)
	CURL_WINDOW_ID = open_curl_tab_if_created()

	COMMAND_BUF_ID = open_command_buffer(filename)

	M.open_result_buffer()
end

M.open_global_curl_tab = function()
	local filename = cache.load_global_command_file()
	setup_curl_tab_for_file(filename)
end

M.open_curl_tab = function()
	local filename = cache.load_command_file()
	setup_curl_tab_for_file(filename)
end

M.open_custom_curl_tab = function(curl_buf_name)
	local filename = cache.load_custom_command_file(curl_buf_name)
	setup_curl_tab_for_file(filename)
end

M.close_curl_tab = function(force)
	if CURL_WINDOW_ID ~= -1 then
		vim.api.nvim_win_close(CURL_WINDOW_ID, force)
	end

	close_curl_buffer(COMMAND_BUF_ID, force)
	close_curl_buffer(OUTPUT_BUF_ID, force)
	CURL_WINDOW_ID, COMMAND_BUF_ID, OUTPUT_BUF_ID = -1, -1, -1
end

M.get_command_buffer_and_pos = function()
	local left_buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(left_buf, 0, -1, false)

	local cursor_pos = vim.api.nvim_win_get_cursor(0)[1]

	return cursor_pos, lines
end

M.set_output_buffer_content = function(content, buf_id)
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, content)
end

return M

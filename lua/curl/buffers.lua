local M = {}

OUTPUT_BUF_ID = -1
COMMAND_BUF_ID = -1
TAB_ID = "curl.nvim.tab"
RESULT_BUF_NAME = "Curl output"

local buf_is_open = function(buffer_name)
	local bufnr = vim.fn.bufnr(buffer_name, false)

	return bufnr ~= -1 and vim.fn.bufloaded(bufnr) == 1
end

local close_curl_buffer = function(buffer, force)
	if buffer == -1 or vim.fn.bufexists(buffer) ~= 1 then
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

local function open_or_goto_curl_tab()
	local tab_win_id = find_curl_tab_windid()
	if tab_win_id ~= nil then
		return tab_win_id
	end

	vim.cmd("tabnew")
	vim.api.nvim_tabpage_set_var(0, "id", TAB_ID)
end

local open_command_buffer = function(command_file)
	close_curl_buffer(COMMAND_BUF_ID, false)
	vim.cmd.edit(command_file)
	local new_bufnr = vim.fn.bufnr(command_file, false)
	local new_win = vim.api.nvim_get_current_win()

	return new_bufnr, new_win
end

local result_open_in_current_tab = function(res_buf_name)
	local buffer = vim.fn.bufnr(res_buf_name, false)

	if not buf_is_open(res_buf_name) then
		return
	end

	local open_windows = vim.api.nvim_tabpage_list_wins(0)
	local windows_containing_buffer = vim.fn.win_findbuf(buffer)

	local set = {}
	for _, win_id in pairs(open_windows) do
		set[win_id] = true ---@type boolean
	end

	for _, win_id in pairs(windows_containing_buffer) do
		if set[win_id] then
			return true
		end
	end

	return false
end

local open_result_buffer = function(called_from_win_id)
	local open_resbuf_name = RESULT_BUF_NAME .. "_" .. called_from_win_id ---@type string

	vim.api.nvim_set_current_win(called_from_win_id)
	if result_open_in_current_tab(open_resbuf_name) then
		return
	end

	if buf_is_open(open_resbuf_name) then
		local bufnr = vim.fn.bufnr(open_resbuf_name, false)
		vim.cmd("vert belowright sb" .. bufnr .. " | wincmd p")
		OUTPUT_BUF_ID = bufnr
		return
	end

	local new_bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(new_bufnr, open_resbuf_name)
	vim.api.nvim_set_option_value("filetype", "json", { buf = new_bufnr })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = new_bufnr })
	vim.cmd("vert belowright sb" .. new_bufnr .. " | wincmd p")
	OUTPUT_BUF_ID = new_bufnr
end

M.setup_curl_tab_for_file = function(filename)
	open_or_goto_curl_tab()

	local new_buf_id, current_win = open_command_buffer(filename)
	COMMAND_BUF_ID = new_buf_id

	close_curl_buffer(OUTPUT_BUF_ID, false)
	open_result_buffer(current_win)
end

M.close_curl_tab = function(force)
	close_curl_buffer(COMMAND_BUF_ID, force)
	close_curl_buffer(OUTPUT_BUF_ID, force)
	COMMAND_BUF_ID, OUTPUT_BUF_ID = -1, -1, -1
end

M.get_command_buffer_and_pos = function()
	local left_buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(left_buf, 0, -1, false)

	local cursor_pos = vim.api.nvim_win_get_cursor(0)[1]

	return cursor_pos, lines
end

M.set_output_buffer_content = function(executed_from_win, content)
	open_result_buffer(executed_from_win)
	vim.api.nvim_buf_set_lines(OUTPUT_BUF_ID, 0, -1, false, content)
end

return M

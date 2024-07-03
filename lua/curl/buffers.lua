local M = {}
local cache = require("curl.cache")

OUTPUT_BUF_ID = -1
COMMAND_BUF_ID = -1
GLOBAL_COMMAND_BUF_ID = -1

local function open_curl_tab_if_created(global)
	local curl_tab_id = global and "curl.nvim.global" or "curl.nvim"
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		local success, tab_id = pcall(function() ---@type any,integer
			return vim.api.nvim_tabpage_get_var(tab, "id")
		end)

		if success and tab_id == curl_tab_id then
			vim.api.nvim_set_current_tabpage(tab)
			vim.api.nvim_set_current_win(vim.api.nvim_tabpage_get_win(tab))
			return true
		end
	end

	vim.cmd("tabnew")
	vim.api.nvim_tabpage_set_var(0, "id", curl_tab_id)
end

local open_command_buffer = function(command_file)
	local bufnr = vim.fn.bufadd(command_file)
	vim.api.nvim_set_option_value("filetype", "sh", { buf = bufnr })
	vim.api.nvim_win_set_buf(0, bufnr)

	return bufnr
end

local open_result_buffer = function()
	OUTPUT_BUF_ID = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("filetype", "json", { buf = OUTPUT_BUF_ID })
	vim.cmd("vert belowright sb" .. OUTPUT_BUF_ID .. " | wincmd p")
end

M.open_global_curl_tab = function()
	if open_curl_tab_if_created(true) then
		return 0
	end

	local file = cache.load_global_command_file()
	GLOBAL_COMMAND_BUF_ID = open_command_buffer(file)

	open_result_buffer()

	return GLOBAL_COMMAND_BUF_ID
end

M.open_curl_tab = function()
	if open_curl_tab_if_created() then
		return 0
	end

	local file = cache.load_command_file()
	COMMAND_BUF_ID = open_command_buffer(file)

	open_result_buffer()

	return COMMAND_BUF_ID
end

M.open_custom_curl_tab = function(curl_buf_name)
	if open_curl_tab_if_created() then
		return 0
	end

	local file = cache.load_custom_command_file(curl_buf_name)
	COMMAND_BUF_ID = open_command_buffer(file)

	open_result_buffer()

	return COMMAND_BUF_ID
end

---@param buffer number
local close_curl_window = function(buffer, force)
	if buffer == -1 then
		return
	end
	vim.api.nvim_buf_delete(buffer, { force = force })
end

M.close_curl_tab = function(force)
	close_curl_window(GLOBAL_COMMAND_BUF_ID, force)
	close_curl_window(COMMAND_BUF_ID, force)
	close_curl_window(OUTPUT_BUF_ID, force)
	GLOBAL_COMMAND_BUF_ID, COMMAND_BUF_ID, OUTPUT_BUF_ID = -1, -1, -1
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

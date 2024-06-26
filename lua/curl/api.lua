local M = {}

local curl_buf_name = "Curl Command"
local output_buf_name = "Curl Output"

local function find_buffer_by_name(name)
	local buf = vim.fn.bufnr(name .. "$")

	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf, name)
	end

	return buf
end

local cache = require("curl.cache")

M.open_curl_tab = function()
	local curl_buffer = find_buffer_by_name(curl_buf_name)
	vim.api.nvim_set_option_value("filetype", "curl", { buf = curl_buffer })

	local output_buffer = find_buffer_by_name(output_buf_name)
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

	vim.api.nvim_buf_set_keymap(
		curl_buffer,
		"n",
		"<CR>",
		"<cmd>lua require('curl.api').execute_curl()<CR>",
		{ noremap = true, silent = true }
	)
end

local get_curl_command = function()
	local left_buf = vim.api.nvim_get_current_buf()
	-- todo: this gets all lines. get current section or selection instead
	-- maybe search until next instance of curl, i.e. 'y/curl'
	local lines = vim.api.nvim_buf_get_lines(left_buf, 0, -1, false)

	local curl_command = table.concat(lines, " ")
	curl_command = curl_command .. " -s -S"

	cache.save_commands_to_cache(lines)
	return curl_command
end

-- Function to execute the curl command and display the output
M.execute_curl = function()
	local curl_command = get_curl_command()

	local output = ""
	local _ = vim.fn.jobstart(curl_command, {
		on_exit = function(_, _, _)
			local right_buf = find_buffer_by_name(output_buf_name)
			if right_buf then
				vim.api.nvim_buf_set_lines(right_buf, 0, -1, false, { output })
				vim.api.nvim_buf_call(right_buf, function()
					vim.cmd("%!jq '.'")
				end)
			end
		end,
		on_stdout = function(_, data, _)
			output = output .. vim.fn.join(data)
		end,
		on_stderr = function(_, data, _)
			output = output .. vim.fn.join(data)
		end,
	})
end

return M

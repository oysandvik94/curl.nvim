local M = {}

local function find_buffer_by_name(name)
	local buf = vim.fn.bufnr(name .. "$")

	if buf ~= -1 then
		return buf
	end

	return nil
end

local cache = require("curl.cache")

M.open_curl_tab = function()
	local left_buf = find_buffer_by_name("Curl Command")
	local right_buf = find_buffer_by_name("Curl Output")

	-- Open a new tab
	vim.cmd("tabnew")

	-- Set up left buffer
	if not left_buf then
		left_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(left_buf, "Curl Command")
	end
	vim.api.nvim_win_set_buf(0, left_buf)
	vim.api.nvim_set_option_value("filetype", "curl", { buf = left_buf })

	-- Load cached commands
	local cached_commands = cache.load_cached_commands()
	if #cached_commands > 0 then
		vim.api.nvim_buf_set_lines(left_buf, 0, -1, false, cached_commands)
	end

	-- Split the window vertically
	vim.cmd("vsplit")
	vim.cmd("wincmd l")

	-- Create or set up right buffer
	if not right_buf then
		right_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(right_buf, "Curl Output")
	end
	vim.api.nvim_win_set_buf(0, right_buf)
	vim.api.nvim_set_option_value("filetype", "json", { buf = right_buf })

	vim.cmd("wincmd h")

	-- Set keybinding for executing the curl command
	vim.api.nvim_buf_set_keymap(
		left_buf,
		"n",
		"<CR>",
		"<cmd>lua require('langeoys.utils.rest').execute_curl()<CR>",
		{ noremap = true, silent = true }
	)
end

-- Function to execute the curl command and display the output
M.execute_curl = function()
	-- Get the current buffer content
	local left_buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(left_buf, 0, -1, false)
	local curl_command = table.concat(lines, " ")
	curl_command = curl_command .. " -s -S"

	cache.save_commands_to_cache(lines)

	local output = ""
	local job = vim.fn.jobstart(curl_command, {
		on_exit = function(jobid, exit_code, event)
			local right_buf = find_buffer_by_name("Curl Output")
			if right_buf then
				vim.api.nvim_buf_set_lines(right_buf, 0, -1, false, { output })
				vim.api.nvim_buf_call(right_buf, function()
					vim.cmd("%!jq '.'")
				end)
			end
		end,
		on_stdout = function(jobid, data, event)
			output = output .. vim.fn.join(data)
		end,
		on_stderr = function(jobid, data, event)
			output = output .. vim.fn.join(data)
		end,
	})
end

return M

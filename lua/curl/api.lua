local M = {}

local parser = require("curl.parser")
local buffers = require("curl.buffers")
local cache = require("curl.cache")
local output_parser = require("curl.output_parser")
local notify = require("curl.notifications")

M.open_curl_tab = function()
	local curl_buffer = buffers.open_curl_tab()

	vim.api.nvim_buf_set_keymap(
		curl_buffer,
		"n",
		"<CR>",
		"<cmd>lua require('curl.api').execute_curl()<CR>",
		{ noremap = true, silent = true }
	)
end

M.execute_curl = function()
	local cursor_pos, lines = buffers.get_command_buffer_and_pos()
	-- todo: cache on insert instead
	cache.save_commands_to_cache(lines)

	local curl_command = parser.parse_curl_command(cursor_pos, lines)

	local output = ""
	local error = ""
	local _ = vim.fn.jobstart(curl_command, {
		on_exit = function(_, exit_code, _)
			if exit_code ~= 0 then
				notify.error("Curl failed")
				buffers.set_output_buffer_content(error)
			end

			local parsed_output = output_parser.parse_curl_output(output)
			buffers.set_output_buffer_content(parsed_output)
		end,
		on_stdout = function(_, data, _)
			output = output .. vim.fn.join(data)
		end,
		on_stderr = function(_, data, _)
			error = error .. vim.fn.join(data)
		end,
	})
end

return M

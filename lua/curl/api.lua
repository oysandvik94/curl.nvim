local M = {}

local parser = require("curl.parser")
local buffers = require("curl.buffers")
local output_parser = require("curl.output_parser")
local notify = require("curl.notifications")
local config = require("curl.config")

local create_execute_mapping = function(buffer)
	local execute_mapping = config.get("mappings")["execute_curl"]
	vim.api.nvim_buf_set_keymap(
		buffer,
		"n",
		execute_mapping,
		"<cmd>lua require('curl.api').execute_curl()<CR>",
		{ noremap = true, silent = true }
	)
end

M.open_custom_tab = function(custom_buf_name)
	buffers.open_custom_curl_tab(custom_buf_name)
	local curl_buffer = buffers.open_curl_tab()
	create_execute_mapping(curl_buffer)
end

M.open_global_tab = function()
	local curl_buffer = buffers.open_global_curl_tab()
	create_execute_mapping(curl_buffer)
end

M.open_curl_tab = function()
	local curl_buffer = buffers.open_curl_tab()
	create_execute_mapping(curl_buffer)
end

---comment
---@param force boolean? if set to true, save warning is ignored
M.close_curl_tab = function(force)
	buffers.close_curl_tab(force)
end

M.execute_curl = function()
	local cursor_pos, lines = buffers.get_command_buffer_and_pos()
	local curl_command = parser.parse_curl_command(cursor_pos, lines)

	if curl_command == "" then
		notify.error("No curl command found under the cursor")
		return
	end

	local output = ""
	local error = ""
	local output_bufnr = OUTPUT_BUF_ID
	local _ = vim.fn.jobstart(curl_command, {
		on_exit = function(_, exit_code, _)
			if exit_code ~= 0 then
				notify.error("Curl failed")
				buffers.set_output_buffer_content(vim.split(error, "\n"), output_bufnr)
				return
			end

			local parsed_output = output_parser.parse_curl_output(output)
			buffers.set_output_buffer_content(parsed_output, output_bufnr)
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

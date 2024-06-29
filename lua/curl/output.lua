M = {}

local buffers = require("curl.buffers")
local notify = require("curl.notifications")

M.write_output = function(curl_standard_out, curl_standard_err)
	local right_buf = buffers.get_or_create_buffer(CURL_OUTPUT_BUF_NAME)

	if curl_standard_err ~= "" then
		notify.error("Curl failed")
		vim.api.nvim_buf_set_lines(right_buf, 0, -1, false, { curl_standard_err })
		return
	end

	vim.api.nvim_buf_set_lines(right_buf, 0, -1, false, { curl_standard_out })
	vim.api.nvim_buf_call(right_buf, function()
		vim.cmd("%!jq '.'")
	end)
end
return M

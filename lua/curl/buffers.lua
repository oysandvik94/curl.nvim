M = {}

M.get_or_create_buffer = function(name)
	local buf = vim.fn.bufnr(name .. "$")

	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf, name)
	end

	return buf
end

return M

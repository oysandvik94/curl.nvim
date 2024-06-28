M = {}

local standard_opts = { timeout = 1, title = "curl.nvim" }

M.error = function(message)
	vim.notify(message, vim.log.levels.ERROR, standard_opts)
end

M.info = function(message)
	vim.notify(message, vim.log.levels.INFO, standard_opts)
end

return M

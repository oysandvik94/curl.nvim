local M = {}
local Path = require("plenary.path")

---@param filename string
---@return string
M.load_custom_command_file = function(filename)
	local curl_filename = filename .. ".curl"
	local cache_dir = Path:new(vim.fn.stdpath("data")) / "curl_cache" / "custom" ---@type Path
	cache_dir:mkdir({ parents = true, exists_ok = true })

	local custom_cache_dir = cache_dir / curl_filename ---@type Path
	return custom_cache_dir:absolute()
end
---
---@return string
M.load_global_command_file = function()
	local cache_dir = Path:new(vim.fn.stdpath("data")) / "curl_cache" ---@type Path
	cache_dir:mkdir({ parents = true, exists_ok = true })

	local global_cache_file = cache_dir / "global.curl" ---@type Path
	return global_cache_file:absolute()
end

---@return string
M.load_command_file = function()
	local workspace_path = vim.fn.getcwd()
	local cache_dir = Path:new(vim.fn.stdpath("data")) / "curl_cache" ---@type Path
	cache_dir:mkdir({ parents = true, exists_ok = true })

	local cwd_cache_dir = cache_dir / (vim.fn.sha256(workspace_path)) ---@type Path
	return cwd_cache_dir:absolute()
end
---

return M

local M = {}
local Path = require("plenary.path")

---comment
---@param global boolean
---@return string
local function get_custom_dir(global)
	if global then
		return "custom"
	else
		local workspace_path = vim.fn.getcwd()
		local unique = vim.fn.fnamemodify(workspace_path, ":t") .. "_" .. vim.fn.sha256(workspace_path):sub(1, 8) ---@type string
		return "scopedcustom/" .. unique
	end
end

---@param filename string
---@return string
M.load_custom_command_file = function(filename, global)
	local custom_dir = get_custom_dir(global)
	local curl_filename = filename .. ".curl"
	local cache_dir = Path:new(vim.fn.stdpath("data")) / "curl_cache" / custom_dir ---@type Path
	cache_dir:mkdir({ parents = true, exists_ok = true })

	local custom_cache_dir = cache_dir / curl_filename ---@type Path
	return custom_cache_dir:absolute()
end

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

	local unique_id = vim.fn.fnamemodify(workspace_path, ":t") .. "_" .. vim.fn.sha256(workspace_path):sub(1, 8) ---@type string
	local new_file_name = unique_id .. ".curl"

	local old_cache_file = cache_dir / vim.fn.sha256(workspace_path) ---@type Path
	local new_cache_file = cache_dir / new_file_name ---@type Path

	if old_cache_file:exists() then
		if not new_cache_file:exists() then
			old_cache_file:rename({ new_name = new_cache_file:absolute() })
		else
			local archive_file = cache_dir / (vim.fn.sha256(workspace_path) .. ".archive") ---@type Path
			old_cache_file:rename({ new_name = archive_file:absolute() })
		end
	end

	return new_cache_file:absolute()
end

return M

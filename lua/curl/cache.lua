local M = {}
local Path = require("plenary.path")
local Config = require("curl.config")

local function get_cache_file()
	local workspace_path = vim.fn.getcwd()
	local cache_dir = Path:new(vim.fn.stdpath("data")) / "curl_cache"
	cache_dir:mkdir({ parents = true, exists_ok = true })
	return cache_dir / (vim.fn.sha256(workspace_path))
end

M.load_cached_commands = function()
	local cache_file = get_cache_file()
	if cache_file:exists() then
		return cache_file:readlines()
	end
	return {}
end

M.save_commands_to_cache = function(commands)
	local cache_file = get_cache_file()
	cache_file:write(table.concat(commands, "\n"), "w")
end

return M

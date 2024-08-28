local M = {}

local cache = {}

M.has_command = function(cmd)
	return vim.fn.executable(cmd) == 1
end

M.has_fish = function()
	if cache.has_fish ~= nil then
		return cache._has_fish
	end
	cache.has_fish = M.has_command("fish")
	return cache.has_fish
end

M.has_sh = function()
	if cache.has_sh ~= nil then
		return cache.has_sh
	end
	cache.has_sh = M.has_command("sh")
	return cache.has_sh
end

M.has_bash = function()
	if cache.has_bash ~= nil then
		return cache.has_bash
	end
	cache.has_bash = M.has_command("bash")
	return cache.has_bash
end

M.has_zsh = function()
	if cache.has_zsh ~= nil then
		return cache.has_zsh
	end
	cache.has_zsh = M.has_command("zsh")
	return cache.has_zsh
end

-- get default shell
---@return table|string
M.get_default_shell = function()
	if M.has_bash() then
		return { "bash", "-c" }
	elseif M.has_sh() then
		return { "sh", "-c" }
	elseif M.has_zsh() then
		return { "zsh", "-c" }
	elseif M.has_fish() then
		return { "fish", "-c" }
	else
		return ""
	end
end

return M

local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local error = health.error or health.report_error

local required_plugins = {
	"plenary",
}

local required_binaries = {
	"curl",
	"jq",
}

local handle_package = function(found, package)
	if found then
		ok(package .. " installed.")
	else
		local err_msg = ("%s: not found:"):format(package)
		error(("%s %s"):format(err_msg, "curl.nvim will not function without this package installed."))
	end
end

local check_plugin_installed = function(plugin)
	local found, _ = pcall(require, plugin)
	handle_package(found, plugin)
end

local check_binary_installed = function(binary)
	local found = vim.fn.executable(binary) == 1
	handle_package(found, binary)
end

local M = {}

M.check = function()
	start("Checking for required plugins")
	for _, plugin in ipairs(required_plugins) do
		check_plugin_installed(plugin)
	end

	start("Checking external dependencies")
	for _, binary in ipairs(required_binaries) do
		check_binary_installed(binary)
	end
end

return M

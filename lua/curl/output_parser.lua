M = {}

local Job = require("plenary.job")

---@diagnostic disable: need-check-nil
M.write_output = function(curl_standard_out)
	local handle = io.popen("echo '" .. curl_standard_out .. "' | jq .")
	local result = handle:read("*a")
	handle:close()

	return vim.split(result, "\n")
end
return M

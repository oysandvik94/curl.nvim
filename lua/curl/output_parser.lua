M = {}

local Job = require("plenary.job")
local notify = require("curl.notifications")

---comment Run jq through plenary
---@param unformatted_json string
---@return table
local function run_jq(unformatted_json)
	local result = {}

	Job:new({
		command = "jq",
		args = { "." },
		writer = unformatted_json,
		on_stdout = function(_, line)
			table.insert(result, line)
		end,
		on_exit = function(_, return_val)
			if return_val ~= 0 then
				vim.schedule(function()
					notify.error("Failed to parse JSON")
				end)

				result = { unformatted_json }
			end
		end,
	}):sync()

	return result
end

---@param curl_standard_out string
---@return table
M.parse_curl_output = function(curl_standard_out)
	if curl_standard_out:match("^[%[%{]") ~= nil then
		return run_jq(curl_standard_out)
	end

	local function trim(s)
		local from = s:match("^%s*()")
		return from > #s and "" or s:match(".*%S", from)
	end

	local jsonString = curl_standard_out
	local split = vim.split(curl_standard_out, "\r")
	for idx, line in ipairs(split) do
		local trimmed_line = trim(line)
		split[idx] = trimmed_line

		if trimmed_line:match("^[%[%{]") ~= nil then
			table.remove(split, idx)
			jsonString = line
			break
		end
	end

	local handle = io.popen("echo '" .. jsonString .. "' | jq .")

	local json_lines = {}
	if handle then
		local result = handle:read("*a")
		handle:close()

		json_lines = vim.split(result, "\n")
	end

	table.move(json_lines, 1, #json_lines, #split + 1, split)
	return split
end
return M

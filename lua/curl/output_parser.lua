M = {}

M.parse_curl_output = function(curl_standard_out)
	if curl_standard_out:match("^[%[%{]") ~= nil then
		local handle = io.popen("echo '" .. curl_standard_out .. "' | jq .")

		if handle then
			local result = handle:read("*a")
			handle:close()

			return vim.split(result, "\n")
		end
		return
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

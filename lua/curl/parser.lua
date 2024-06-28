M = {}

local remove_trailing_forwardslash = function(lines)
	local cleaned_lines = {}
	for _, line in ipairs(lines) do
		local cleaned_line = line:gsub("%s*\\%s*$", "")
		table.insert(cleaned_lines, cleaned_line)
	end

	return cleaned_lines
end

local find_backward
find_backward = function(current_pos, lines)
	local next_pos = current_pos - 1

	if current_pos <= 0 then
		return current_pos
	end

	if lines[current_pos]:match("^curl") ~= nil then
		return current_pos
	end

	local next_line = lines[next_pos]
	if next_line == nil then
		return current_pos
	end

	local trimmed_line = next_line:gsub("%s+", "")
	if trimmed_line == "" then
		return current_pos
	end

	if next_line:match("^curl") ~= nil then
		return next_pos
	end

	return find_backward(next_pos, lines)
end

local find_forwards
find_forwards = function(current_pos, lines)
	local next_pos = current_pos + 1

	if current_pos >= #lines then
		return current_pos
	end

	local next_line = lines[next_pos]
	if next_line == nil then
		return current_pos
	end

	local trimmed_line = next_line:gsub("%s+", "")
	if trimmed_line == "" then
		return current_pos
	end

	if next_line:match("^curl") ~= nil then
		return current_pos
	end

	return find_forwards(next_pos, lines)
end

M.parse_curl_command = function(lines)
	local cleaned_lines = remove_trailing_forwardslash(lines)

	local cursor = vim.api.nvim_win_get_cursor(0)[1]
	local first_line = find_backward(cursor, cleaned_lines)
	local last_line = find_forwards(cursor, cleaned_lines)

	local result = ""
	for i = first_line, last_line do
		result = result .. " " .. cleaned_lines[i]
	end

	result = result .. " -s -S"
	return result
end

return M

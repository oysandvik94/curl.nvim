M = {}

---comment
---@param stack {}
---@param opening_char string
---@param closing_char string
---@param line string
---@return boolean
local function is_line_json_close(stack, opening_char, closing_char, line)
	for char in string.gmatch(line, ".") do
		if char == opening_char then
			table.insert(stack, opening_char)
		end

		if char == closing_char then
			table.remove(stack)

			if #stack == 0 then
				return true
			end
		end
	end

	return false
end

---@param line any
---@return unknown
local function remove_trailing_forwardslash(line)
	return line:gsub("%s*\\%s*$", "")
end

local function found_first_json_char(stack, line)
	return #stack == 0 and line:match("^[%[%{]") ~= nil
end

---comment removes trailing \ character from newlines,
---and adds single quotes to the beginning and end of json strings if they are missing
---@param lines table
---@return table
local format_command_for_curl = function(lines)
	local cleaned_lines = {}

	local opening_json_char
	local closing_json_char
	local json_nesting_stack = {}

	for _, line in ipairs(lines) do
		local cleaned_line = remove_trailing_forwardslash(line)

		if found_first_json_char(json_nesting_stack, cleaned_line) then
			opening_json_char = cleaned_line:sub(1, 1)
			closing_json_char = opening_json_char == "[" and "]" or "}"
			is_line_json_close(json_nesting_stack, opening_json_char, closing_json_char, cleaned_line)

			cleaned_line = "'" .. cleaned_line
		elseif #json_nesting_stack > 0 then
			local found_json_end =
				is_line_json_close(json_nesting_stack, opening_json_char, closing_json_char, cleaned_line)
			if found_json_end then
				cleaned_line = cleaned_line .. "'"
			end
		end

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

M.parse_curl_command = function(cursor_pos, lines)
	if #lines == 0 then
		return ""
	end

	local cleaned_lines = format_command_for_curl(lines)

	local first_line = find_backward(cursor_pos, cleaned_lines)
	local last_line = find_forwards(cursor_pos, cleaned_lines)

	local result = ""
	for i = first_line, last_line do
		if i > first_line then
			result = result .. " "
		end
		result = result .. cleaned_lines[i]
	end

	result = result .. " -s -S"
	return result
end

return M

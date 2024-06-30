M = {}

---comment
---@param stack {}
---@param opening_char string
---@param closing_char string
---@param line {}
---@return boolean
local function handle_stack(stack, opening_char, closing_char, line)
	if line:sub(1, 1) == opening_char then
		table.insert(stack, opening_char)
	end

	if line:sub(1, 1) == closing_char then
		table.remove(stack)

		if #stack == 0 then
			return true
		end
	end

	return false
end

---@param lines table
---@return table
local remove_trailing_forwardslash = function(lines)
	local cleaned_lines = {}

	local opening_json_char
	local closing_json_char
	local json_seperator_stack = {}

	for _, line in ipairs(lines) do
		local cleaned_line = line:gsub("%s*\\%s*$", "")

		if #json_seperator_stack == 0 and cleaned_line:match("^[%[%{]") ~= nil then
			opening_json_char = cleaned_line:sub(1, 1)
			closing_json_char = opening_json_char == "[" and "]" or "}"
			handle_stack(json_seperator_stack, opening_json_char, closing_json_char, cleaned_line)

			cleaned_line = "'" .. cleaned_line
		elseif #json_seperator_stack > 0 then
			local found_json_end =
				handle_stack(json_seperator_stack, opening_json_char, closing_json_char, cleaned_line)
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

	local cleaned_lines = remove_trailing_forwardslash(lines)

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

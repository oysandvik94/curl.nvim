local M = {}

local config = require("curl.config")

local highlight_curl_command = function(start_pos, end_pos)
  local ns_id = vim.api.nvim_create_namespace("curl_command_highlight")

  for i = start_pos - 1, end_pos - 1 do -- Lua is 1-indexed, but nvim_buf_add_highlight is 0-indexed
    vim.api.nvim_buf_add_highlight(0, ns_id, "CurlCommandHighlight", i, 0, -1)
  end

  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, start_pos - 1, end_pos)
  end, 200)
end

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

local function is_commented(line)
  return line:match("^%s*%#") ~= nil
end

---comment removes trailing \ character from newlines,
---and adds single quotes to the beginning and end of json strings if they are missing
---@param lines table
---@return table
local format_command_for_curl = function(lines)
  local cleaned_lines = {}

  local opening_json_char, closing_json_char
  local json_nesting_stack = {}

  for _, line in ipairs(lines) do
    local cleaned_line = remove_trailing_forwardslash(line)

    if found_first_json_char(json_nesting_stack, cleaned_line) then
      opening_json_char = cleaned_line:sub(1, 1)
      closing_json_char = opening_json_char == "[" and "]" or "}"
      cleaned_line = "'" .. cleaned_line

      if is_line_json_close(json_nesting_stack, opening_json_char, closing_json_char, cleaned_line) then
        cleaned_line = cleaned_line .. "'"
      end
    elseif #json_nesting_stack > 0 then
      local found_json_end = is_line_json_close(json_nesting_stack, opening_json_char, closing_json_char, cleaned_line)
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

  if current_pos <= 1 then
    return current_pos
  end

  if lines[current_pos]:match("^curl|const") ~= nil then
    return current_pos
  end

  local next_line = lines[next_pos]:gsub("%s+", "")
  if next_line == "" then
    return current_pos
  end

  return find_backward(next_pos, lines)
end

local find_forwards
find_forwards = function(current_pos, lines)
  local next_pos = current_pos + 1

  if current_pos >= #lines then
    return current_pos
  end

  local next_line = lines[next_pos]:gsub("%s+", "")
  if next_line == "" then
    return current_pos
  end

  if next_line:match("^curl|const") ~= nil then
    return current_pos
  end

  return find_forwards(next_pos, lines)
end

---@class CurlTokens
---@field  boolean
---@field cond? boolean
---@field dep? boolean True if this plugin is only in the spec as a dependency
---@field dir? string Explicit dir or dev set for this plugin
---@field dirty? boolean
---@field build? boolean
---@field frags? number[]
---@field handlers? LazyPluginHandlers
---@field installed? boolean
---@field is_local? boolean
---@field kind? LazyPluginKind
---@field loaded? {[string]:string}|{time:number}
---@field outdated? boolean
---@field rtp_loaded? boolean
---@field tasks? LazyTask[]
---@field updated? {from:string, to:string}
---@field updates? {from:GitInfo, to:GitInfo}
---@field last_check? number
---@field working? boolean
---@field pkg? LazyPkg

---comment
---@param input string
---@return table
M.tokenize = function(input)
  local tokens = {
    command = "",
    variable = "",
  }

  local curl = "curl"

  local buffer = ""
  local i = 1
  while i <= #input do
    local char = input:sub(i, i)

    buffer = buffer .. char

    if buffer == "const" then
      i = i + 1
      local should_be_whitespace = input:sub(i, i)
      if should_be_whitespace ~= " " then
        error("'const' should be followed by whitespace")
      end

      local keyword_buffer = ""
      i = i + 1
      local inner_char = input:sub(i, i)

      while inner_char ~= " " do
        i = i + 1
        inner_char = input:sub(i, i)
      end
    end

    if buffer == curl then
      local rest_of_curl = input:sub(i, -1)
      tokens.command = curl .. rest_of_curl
      return tokens
    end

    i = i + 1
  end

  -- Parsing logic to populate the tokens table would go here

  return tokens
end

M.parse_curl_command = function(cursor_pos, lines)
  if #lines == 0 then
    return ""
  end

  local cleaned_lines = format_command_for_curl(lines)

  local first_line = find_backward(cursor_pos, cleaned_lines)
  local last_line = find_forwards(cursor_pos, cleaned_lines)

  highlight_curl_command(first_line, last_line)

  local selection = {}
  for i = first_line, last_line do
    if not is_commented(cleaned_lines[i]) then
      table.insert(selection, cleaned_lines[i])
    end
  end

  if selection[1]:match("^%s*curl") == nil then
    return ""
  end

  -- tokenize(selection)

  table.insert(selection, "-sSL")

  ---@for _ int, flag string in ipairs
  for _, flag in ipairs(config.get("default_flags")) do
    table.insert(selection, flag)
  end

  return vim.fn.join(selection, " ")
end

return M

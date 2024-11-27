local M = {}

---@class CurlTokens
---@field command string
---@field variable? string

---@class IteratorState
---@field input string
---@field next_char number

---Advances the iterator state by one character and returns the character.
---@param iterator_state IteratorState
---@return string
local function get_next(iterator_state)
  iterator_state.next_char = iterator_state.next_char + 1
  return iterator_state.input:sub(iterator_state.next_char, iterator_state.next_char)
end

---Peeks at the next character without advancing the iterator state.
---@param iterator_state IteratorState
---@return string
local function peek_next(iterator_state)
  return iterator_state.input:sub(iterator_state.next_char + 1, iterator_state.next_char + 1)
end

---Consumes characters until an equals sign is encountered, skipping whitespace.
---@param iterator_state IteratorState
local function read_until_equals(iterator_state)
  while peek_next(iterator_state) == " " do
    get_next(iterator_state)
  end

  if get_next(iterator_state) ~= "=" then
    error("Expected '=' after declaration.")
  end

  while peek_next(iterator_state) == " " do
    get_next(iterator_state)
  end
end

---Tokenizes the input string into command and variable tokens.
---@param input string
---@return CurlTokens
M.tokenize = function(input)
  local tokens = { command = "", variable = "" }
  local iterator_state = { input = input, next_char = -1 }
  local curl_keyword = "curl"
  local buffer = ""

  while iterator_state.next_char <= #input do
    local char = get_next(iterator_state)
    buffer = buffer .. char

    if buffer == "const" then
      if get_next(iterator_state) ~= " " then
        error("'const' should be followed by whitespace")
      end

      local keyword_buffer = ""
      while peek_next(iterator_state) ~= " " do
        keyword_buffer = keyword_buffer .. get_next(iterator_state)
      end

      tokens.variable = keyword_buffer
      read_until_equals(iterator_state)
      buffer = ""
    end

    if buffer == curl_keyword then
      tokens.command = curl_keyword .. input:sub(iterator_state.next_char + 1)
      return tokens
    end
  end

  return tokens
end

return M

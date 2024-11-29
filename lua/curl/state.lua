local M = {}

local variable_map = {}

---comment
---@param key string
---@param value table
M.store_value = function(key, value)
  local json_string = table.concat(value, "\n")
  local decoded_json = vim.json.decode(json_string)
  variable_map[key] = decoded_json
end

M.get_value = function(key)
  return variable_map[key]
end
return M

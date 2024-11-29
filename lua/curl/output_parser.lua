local M = {}

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

local function trim(s)
  local from = s:match("^%s*()")
  return from > #s and "" or s:match(".*%S", from)
end

local function no_headers(line)
  return line:match("^[%[%{]") ~= nil
end

local function extract_json(output_lines)
  local header_lines = {}
  local json_string = nil

  for _, line in ipairs(output_lines) do
    local trimmed_line = trim(line)
    if no_headers(trimmed_line) then
      json_string = trimmed_line
      break
    end
    table.insert(header_lines, trimmed_line)
  end

  return header_lines, json_string
end

---@class CurlOutput
---@field response table
---@field headers table

---
---@param curl_standard_out string
---@return CurlOutput
M.parse_curl_output = function(curl_standard_out)
  ---@class CurlOutput
  local curl_output = {}

  if no_headers(curl_standard_out) then
    curl_output.response = run_jq(curl_standard_out)
  end

  local output_table = vim.split(curl_standard_out, "\r")
  local header_lines, json_string = extract_json(output_table)
  curl_output.headers = header_lines

  if json_string ~= nil then
    curl_output.response = run_jq(json_string)
  end

  return curl_output
end
return M

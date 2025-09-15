M.execute_curl = function()
  local executed_from_win = vim.api.nvim_get_current_win()
  local cursor_pos, lines = buffers.get_command_buffer_and_pos()
  local curl_command = parser.parse_curl_command(cursor_pos, lines)

  local curl_alias = config.get("curl_binary")
  if curl_alias ~= nil then
    curl_command = curl_command:gsub("^curl", curl_alias)
  end

  if curl_command == "" then
    notify.error("No curl command found under the cursor")
    return
  end

  -- Parse variables from the buffer content
  local vars = variables.parse_variables(table.concat(lines, "\n"))
  curl_command = variables.replace_placeholders(curl_command, vars)
  buffers.setup_buf_vars(lines, cursor_pos)

  local output = ""
  local error = ""
  local commands = shell.get_default_shell()
  if commands ~= nil and type(commands) == "table" then
    table.insert(commands, curl_command)
  else
    commands = curl_command
  end

  local start_time = vim.uv.hrtime()

  local _ = vim.fn.jobstart(commands, {
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        notify.error("Curl failed")
        buffers.set_output_buffer_content(executed_from_win, vim.split(error, "\n"))
        return
      end

      local show_request_duration = config.get().show_request_duration_limit
      if show_request_duration then
        local elapsed = (vim.uv.hrtime() - start_time) / 1e9
        if elapsed > show_request_duration then
          print(string.format("Request took %.3f seconds", elapsed))
        end
      end

      local parsed_output = output_parser.parse_curl_output(output)
      buffers.set_output_buffer_content(executed_from_win, parsed_output)
    end,
    on_stdout = function(_, data, _)
      output = output .. vim.fn.join(data)
    end,
    on_stderr = function(_, data, _)
      error = error .. vim.fn.join(data)
    end,
  })
end

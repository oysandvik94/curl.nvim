local M = {}

M.assert_commands = function(expected, received)
  local expected_silenced = ""
  if #expected > 0 then
    expected_silenced = expected .. " -sSL"
  end

  M.assert_equals(expected_silenced, received.command)
end

M.assert_equals = function(expected, received, message)
  MiniTest.expect.equality(expected, received)
end

M.assert_table_equals = function(expected, received)
  for index, value in ipairs(expected) do
    M.assert_equals(value, received[index])
  end
end

return M

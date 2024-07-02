local M = {}

M.assert_commands = function(expected, received)
	local expected_silenced = ""
	if #expected > 0 then
		expected_silenced = expected .. " -sSL"
	end

	M.assert_equals(expected_silenced, received)
end

M.assert_equals = function(expected, received)
	local _, err = pcall(function()
		assert(expected == received)
	end)

	if err then
		vim.print("Assertion failed")
		vim.print("Expected:")
		vim.print(expected)
		vim.print("Got:")
		vim.print(received)
		assert(false)
	end
end

M.assert_table_equals = function(expected, received)
	for index, value in ipairs(expected) do
		M.assert_equals(value, received[index])
	end
end

return M

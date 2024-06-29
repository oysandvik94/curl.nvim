M = {}

M.assert_commands = function(expected, received)
	local expected_silenced = ""
	if #expected > 0 then
		expected_silenced = expected .. " -s -S"
	end

	M.assert_equals(expected_silenced, received)
end

M.assert_equals = function(expected, received)
	local fail_message = "\nExpected command: \n" .. expected .. " \nbut got: \n" .. received
	assert(expected == received, fail_message)
end

return M

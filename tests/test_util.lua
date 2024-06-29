M = {}

M.assert_commands = function(expected, received)
	local expected_silenced = ""
	if #expected > 0 then
		expected_silenced = expected .. " -s -S"
	end

	local fail_message = "\nExpected command: \n" .. expected_silenced .. " \nbut got: \n" .. received
	assert(expected_silenced == received, fail_message)
end

return M

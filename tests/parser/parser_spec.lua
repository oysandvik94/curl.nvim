local function assert_commands(expected, received)
	local expected_silenced = ""
	if #expected > 0 then
		expected_silenced = expected .. " -s -S"
	end

	local fail_message = "\nExpected command: \n" .. expected_silenced .. " \nbut got: \n" .. received
	assert(expected_silenced == received, fail_message)
end

describe("Able to parse simple buffer", function()
	local parser = require("curl.parser")

	it("containing zero curl command", function()
		local input_buffer = {}
		local cursor_pos = 1

		local parsed_command = parser.parse_curl_command(cursor_pos, input_buffer)

		assert_commands("", parsed_command)
	end)

	it("containing one curl command", function()
		local input_buffer = {
			"curl https://jsonplaceholder.typicode.com/todos/1",
		}
		local cursor_pos = 1

		local parsed_command = parser.parse_curl_command(cursor_pos, input_buffer)

		local expected_curl_command = "curl https://jsonplaceholder.typicode.com/todos/1"
		assert_commands(expected_curl_command, parsed_command)
	end)

	it("containing many curl commands", function()
		local input_buffer = {
			"curl https://first.com/todos/1",
			"curl https://second.com/todos/1",
			"curl https://third.com/todos/1",
		}

		for index, curl_line in ipairs(input_buffer) do
			local parsed_command = parser.parse_curl_command(index, input_buffer)

			assert_commands(curl_line, parsed_command)
		end
	end)
end)

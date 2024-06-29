local output_parser = require("lua.curl.output_parser")
local test_util = require("tests.test_util")

describe("Output from curl", function()
	it("is parsed json", function()
		local output = output_parser.parse_curl_output('{ "test": 2 }')

		local expected = {
			"{",
			'  "test": 2',
			"}",
			"",
		}

		test_util.assert_table_equals(expected, output)
	end)

	it("can parse headers", function()
		local expected = {
			"HTTP/2 200",
			"date: Sat, 29 Jun 2024 15:36:55 GMT",
			"content-type: application/json; charset=utf-8",
			"content-length: 83",
			"",
			"{",
			'  "userId": 1,',
			'  "id": 1,',
			'  "title": "dele ctus aut autem",',
			'  "completed": false',
			"}",
		}

		local input =
			'HTTP/2 200 \r date: Sat, 29 Jun 2024 15:36:55 GMT\r content-type: application/json; charset=utf-8\r content-length: 83\r \r {"userId": 1,   "id": 1,   "title": "dele ctus aut autem",   "completed": false }'

		local output = output_parser.parse_curl_output(input)

		test_util.assert_table_equals(expected, output)
	end)
end)

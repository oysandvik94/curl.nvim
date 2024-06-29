local output_parser = require("lua.curl.output_parser")
local test_util = require("tests.test_util")

describe("Output from curl", function()
	it("is parsed json", function()
		local output = output_parser.write_output('{ "test": 2 }')

		local expected = {
			"{",
			'  "test": 2',
			"}",
			"",
		}

		test_util.assert_table_equals(expected, output)
	end)
end)

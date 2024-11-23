local parser = require("curl.parser")
local test_util = require("tests.testing_util")

describe("Able to parse simple buffer", function()
  it("containing zero curl command", function()
    local input_buffer = {}
    local cursor_pos = 1

    local parsed_command = parser.parse_curl_command(cursor_pos, input_buffer)

    test_util.assert_commands("", parsed_command)
  end)

  it("containing one curl command", function()
    local input_buffer = {
      "curl https://jsonplaceholder.typicode.com/todos/1",
    }
    local cursor_pos = 1

    local parsed_command = parser.parse_curl_command(cursor_pos, input_buffer)

    local expected_curl_command = "curl https://jsonplaceholder.typicode.com/todos/1"
    test_util.assert_commands(expected_curl_command, parsed_command)
  end)

  it("containing many curl commands", function()
    local input_buffer = {
      "curl https://first.com/todos/1",
      "curl https://second.com/todos/1",
      "curl https://third.com/todos/1",
    }

    for index, curl_line in ipairs(input_buffer) do
      local parsed_command = parser.parse_curl_command(index, input_buffer)

      test_util.assert_commands(curl_line, parsed_command)
    end
  end)

  it("containing many spaced curl commands", function()
    local input_buffer = {
      "",
      "curl https://first.com/todos/1",
      "",
      "curl https://second.com/todos/1",
      "",
      "curl https://third.com/todos/1",
      "",
    }

    test_util.assert_commands(input_buffer[2], parser.parse_curl_command(2, input_buffer))
    test_util.assert_commands(input_buffer[4], parser.parse_curl_command(4, input_buffer))
    test_util.assert_commands(input_buffer[6], parser.parse_curl_command(6, input_buffer))
  end)

  it("containing multiline curl-command", function()
    local input_buffer = {
      "curl https://first.com/todos/1",
      "curl -X POST https://jsonplaceholder.typicode.com/posts",
      "-H 'Content-Type: application/json'",
      "-d",
      "'{",
      '"title": "foo",',
      '"body": "bar",',
      '"userId": 123',
      "}'",
      "curl https://third.com/todos/1",
    }

    test_util.assert_commands(input_buffer[1], parser.parse_curl_command(1, input_buffer))
    test_util.assert_commands(input_buffer[#input_buffer], parser.parse_curl_command(#input_buffer, input_buffer))

    -- All cursor positions in the multiline curl is valid
    local expected_command =
      'curl -X POST https://jsonplaceholder.typicode.com/posts -H \'Content-Type: application/json\' -d \'{ "title": "foo", "body": "bar", "userId": 123 }\''

    for index = 2, 9 do
      local parsed_command = parser.parse_curl_command(index, input_buffer)
      test_util.assert_commands(expected_command, parsed_command)
    end
  end)
end)

describe("Has feature", function()
  it("parsing multiline commands with trailing forward slash", function()
    local input_buffer = {
      "curl https://first.com/todos/1",
      "curl -X POST https://jsonplaceholder.typicode.com/posts \\",
      "-H 'Content-Type: application/json' \\",
      "-d \\",
      "'{ \\",
      '"title": "foo", \\',
      '"body": "bar", \\',
      '"userId": 123 \\',
      "}'",
      "curl https://third.com/todos/1",
    }

    -- All cursor positions in the multiline curl is valid
    local expected_command =
      'curl -X POST https://jsonplaceholder.typicode.com/posts -H \'Content-Type: application/json\' -d \'{ "title": "foo", "body": "bar", "userId": 123 }\''

    for index = 2, 9 do
      local parsed_command = parser.parse_curl_command(index, input_buffer)
      test_util.assert_commands(expected_command, parsed_command)
    end
  end)

  it("parse json object without surrounding quotes", function()
    local input_buffer = {
      "curl -X POST https://jsonplaceholder.typicode.com/posts",
      "-H 'Content-Type: application/json'",
      "-d",
      "{",
      '"title": "foo",',
      '"body": "bar",',
      '"userId": 123',
      "}",
    }

    local expected_command =
      'curl -X POST https://jsonplaceholder.typicode.com/posts -H \'Content-Type: application/json\' -d \'{ "title": "foo", "body": "bar", "userId": 123 }\''

    for index = 1, #input_buffer do
      local parsed_command = parser.parse_curl_command(index, input_buffer)
      test_util.assert_commands(expected_command, parsed_command)
    end
  end)

  it("parse json array without surrounding quotes", function()
    local input_buffer = {
      "curl -X POST https://jsonplaceholder.typicode.com/posts",
      "-H 'Content-Type: application/json'",
      "-d",
      "[",
      "{",
      '"title": "foo",',
      '"body": "bar",',
      '"userId": 123',
      "},",
      "{",
      '"title": {',
      '"foo": "bar"',
      "},",
      '"body": "bar",',
      '"userId": 123',
      "}",
      "]",
    }

    local expected_command =
      'curl -X POST https://jsonplaceholder.typicode.com/posts -H \'Content-Type: application/json\' -d \'[ { "title": "foo", "body": "bar", "userId": 123 }, { "title": { "foo": "bar" }, "body": "bar", "userId": 123 } ]\''

    for index = 1, #input_buffer do
      local parsed_command = parser.parse_curl_command(index, input_buffer)
      test_util.assert_commands(expected_command, parsed_command)
    end
  end)

  it("parse json array without surrounding quotes that is also mangled", function()
    local input_buffer = {
      "curl -X POST https://jsonplaceholder.typicode.com/posts",
      "-H 'Content-Type: application/json'",
      "-d",
      "[{",
      '"title": "foo",',
      '"body": "bar",',
      '"userId": 123',
      "},",
      "{",
      '"title": {',
      '"foo": "bar"',
      "},",
      '"body": "bar",',
      '"userId": 123}]',
    }

    local expected_command =
      'curl -X POST https://jsonplaceholder.typicode.com/posts -H \'Content-Type: application/json\' -d \'[{ "title": "foo", "body": "bar", "userId": 123 }, { "title": { "foo": "bar" }, "body": "bar", "userId": 123}]\''

    for index = 1, #input_buffer do
      local parsed_command = parser.parse_curl_command(index, input_buffer)
      test_util.assert_commands(expected_command, parsed_command)
    end
  end)

  it("can ignore comments", function()
    local input_buffer = {
      "curl -X POST https://jsonplaceholder.typicode.com/posts",
      "-H 'Content-Type: application/json'",
      "-d",
      "{",
      '  "title": "foo",',
      '  #"body": "bar",',
      '  "userId": 123',
      "}",
    }

    local expected_command =
      'curl -X POST https://jsonplaceholder.typicode.com/posts -H \'Content-Type: application/json\' -d \'{   "title": "foo",   "userId": 123 }\''

    for index = 1, #input_buffer do
      local parsed_command = parser.parse_curl_command(index, input_buffer)
      test_util.assert_commands(expected_command, parsed_command)
    end
  end)

  it("not bug out on comment", function()
    local input_buffer = {
      "curl -X POST https://jsonplaceholder.typicode.com/posts",
      "-H 'Content-Type: application/json'",
      "-d",
      "[",
      "{",
      '"title": "remember me",',
      '# "title": "now try this"',
      "}]",
    }

    local expected_command =
      "curl -X POST https://jsonplaceholder.typicode.com/posts -H 'Content-Type: application/json' -d '[ { \"title\": \"remember me\", }]'"

    for index = 1, #input_buffer do
      local parsed_command = parser.parse_curl_command(index, input_buffer)
      test_util.assert_commands(expected_command, parsed_command)
    end
  end)

  it("json content in one line", function()
    local input_buffer = {
      "curl -X POST https://jsonplaceholder.typicode.com/posts",
      "-H 'Content-Type: application/json'",
      "-d",
      '{ "title": "now try this" }',
    }

    local expected_command =
      "curl -X POST https://jsonplaceholder.typicode.com/posts -H 'Content-Type: application/json' -d '{ \"title\": \"now try this\" }'"

    for index = 1, #input_buffer do
      local parsed_command = parser.parse_curl_command(index, input_buffer)
      test_util.assert_commands(expected_command, parsed_command)
    end
  end)
end)

# Contributing

You are always welcome to fork this project and submit a PR!

Also feel free to create an issue if you would like to discuss a feature beforehand.

## Features

One of the philosophies behind curl.nvim is that it's as close to curl as possible.
Very little should be abstracted a way.

As a rule, any valid curl command in the shell should be able to be pasted in
to the curl buffer, and be run.

## Bugs

If you fix a bug, please provide a test that reproduces the bug, and that would fail if one
were to revert your changes. This ensures no regressions, and makes it clear how the bug was caused.

## Project

- api.lua
  - Lua functions that the user should be able to access
- buffers.lua
  - Logic related to opening the correct buffers, and outputting
    content to the correct buffers
- cache.lua
  - Logic related to caching curl commands between sessions
- config.lua
  - Things that are configurable goes here
- init.lua
  - Setup code that should be run once goes here, such as highlight groups, usercommands and so on
- notifications.lua
  - Unified way to show notifications for the user
- output_parser.lua
  - Logic for parsing the output from curl commands. Takes care of running jq, and seperating headers and json output
- parser.lua
  - See [parser](CONTRIBUTING#Parser)

### Parser

This is where most of the complex logic lives, and takes care
of the qol features in the scratch buffer.

The parses works on simple text instead of using i.e. treesitter,
as the legal format of commands in the scratch buffer is not
valid bash.

The parsing logic aims to be simple rather than complex.
`format_command_for_curl` removes any trailing forward-slashes and adds missing quotes to json bodies.

Adding missing quotes works by finding the first character of a valid
json body, either "{" or "[", then uses a stack to keep track of
nested objects and arrays. When the stack is empty, we know that we
found the closer of the json body, which we can append a closing
quote to.

After cleaning up the json body, we look for the curl command
in the document to execute based on the cursor position.
First we go upwards until we find either a newline, or
another curl command.
We do the same downwards.

The first and last line is the boundary for the curl command.

## Tests

Tests can be run like this:

`./test/run`

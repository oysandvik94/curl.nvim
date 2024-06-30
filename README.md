<div align="center">
<img src="https://github.com/oysandvik94/curl.nvim/assets/25078429/65ad4dd4-cb7a-4ef9-a503-ff6693129efb" data-canonical-src="https://github.com/oysandvik94/curl.nvim/assets/25078429/65ad4dd4-cb7a-4ef9-a503-ff6693129efb" width="300" height="300" />
  
  # curl.nvim
  
💪 Integrate curl and jq in Neovim. 💪

</div>

https://github.com/oysandvik94/curl.nvim/assets/25078429/9c25d289-c293-41c4-9d8d-40a0e8b013ed

> [!WARNING]  
> This is my first plugin, and it is in early development. I will fix bugs as fast as I can. Please be patient!

# Features

curl.nvim allows you to run HTTP requests with curl from a scratchpad, and display the formatted output

The scratch buffer also persists after closing Neovim, persisting based on the current working
directory.

The plugin aims to be 100% compatible with curl; if a curl command can execute in your shell,
you will be able to paste it in to the scratch buffer and run it.
Because of this, the plugin attempts to get the balance of being ergonomic and convenient, while
still using the knowledge of curl you already have.

However, there are a few quality of life features:

- ✨ JSON bodies do not have to be wrapped in quotes, making it easier to format JSON with JQ (va{:!jq)

<details>
<summary>See example</summary>

```bash
curl -X POST https://jsonplaceholder.typicode.com/posts
-H 'Content-Type: application/json'
-d
{
  "id": 2
  "title": "now try this"
}
```

</details>

- ✨ You dont need a trailing \\, but it wont matter if they are there, making it easier to copy-paste
  requests

<details>
<summary>See example</summary>

```bash
curl -X POST https://jsonplaceholder.typicode.com/posts \
-H 'Content-Type: application/json' \
-d '{"title": "now try this"}'
```

</details>

- ✨ Headers and parts of the body can be commented out using '#', making ad-hoc experimenting with
  requests easier

<details>
<summary>See example</summary>

```bash
curl -X POST https://jsonplaceholder.typicode.com/posts
-H 'Content-Type: application/json'
-d
{
  # "title": "remember me"
  "title": "now try this"
}
```

</details>

To get started, just install the plugin, run ":CurlOpen" and fire away!

## Installation and requirements

The plugin requires you to have curl on your system, which you most likely have.

If you dont have [jq](https://jqlang.github.io/jq/), you can most likely download it on your system
through your preferred package manager. _curl.nvim_ uses jq to format JSON, but it's an amazing tool
that I recommend you experiment with.

Installation example for [Lazy](https://github.com/folke/lazy.nvim):

```lua
{
  "oysandvik94/curl.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("curl").setup({})
  end
}

```

## Configuration

You can configure curl.nvim by running the `curl.setup()` function, passing a table as the argument.

<details>
<summary>Default Config</summary>

```lua
local curl = require("curl").setup()

curl.setup {
    mappings = {
        execute_curl = "<CR>"
    }
}
```

</details>

## Usage

You can either open or close curl.nvim with the usercommands:

```vim
:CurlOpen
:CurlClose
```

CurlOpen will open a new tab containing two buffers split vertically.

In the left buffer, you can paste or write curl commands, and by pressing Enter, the
command will execute, and the output will be shown and formatted in the rightmost buffer.

If you wish, you can select the text in the right buffer, and filter it using jq, i.e.
`ggVG! jq '{query goes here}'`

See examples in the introduction for how you can format your curl requests.

### Lua api

The plugin also exposes this lua api:

<details>
<summary>See lua api</summary>

```lua
local curl = require('curl')

curl.open_curl_tab()
curl.close_curl_tab()

-- Executes the curl command under the cursor when the command buffer is open
-- Also executed by the "execute_curl" mapping, as seen in the configuration. Mapped to <CR> by default
curl.execute_curl()

```

</details>

## Future plans

Interesting features that might arrive soon:

- Format JSON under the cursor in the scratch window with a single keybind
- Be able to do simple jq queries in the output window. For example: while the cursor is
  on a key in the json, execute a keybind to filter the entire json for that key
- Enhance organization, by maybe folds, creating a picker for commands in the scratch,
  or multiple named scratches

## Alternatives

- [rest.nvim](https://github.com/rest-nvim/rest.nvim) has a similar UI, using HTTP file syntax instead.
  This is similar to Jetbrains HTTP clien

## Contributing

Would you like to contribute? Noice, read [CONTRIBUTING.md](CONTRIBUTING.md)!

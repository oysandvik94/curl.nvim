<div align="center">
<img src="https://github.com/oysandvik94/curl.nvim/assets/25078429/65ad4dd4-cb7a-4ef9-a503-ff6693129efb" data-canonical-src="https://github.com/oysandvik94/curl.nvim/assets/25078429/65ad4dd4-cb7a-4ef9-a503-ff6693129efb" width="300" height="300" />
  
  # curl.nvim
  
Integrate curl and jq in Neovim.

</div>

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

todo: describe usage more in detail

### Lua api

The plugin also exposes this lua api:

<details>
<summary>See lua api</summary>
</details>

```lua
local curl = require('curl')

curl.open_curl_tab()
curl.close_curl_tab()

-- Executes the curl command under the cursor when the command buffer is open
-- Also executed by the "execute_curl" mapping, as seen in the configuration. Mapped to <CR> by default
curl.execute_curl()

```

## Contributing

Would you like to contribute? Noice, read [CONTRIBUTING.md](CONTRIBUTING.md)!

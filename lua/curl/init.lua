local M = {}

local api = require("curl.api")

local create_curl_open = function()
	vim.api.nvim_create_user_command("CurlOpen", function(opts)
		if opts.args == "global" then
			require("curl.api").open_global_tab()
		elseif opts.args:match("^custom%s+") then
			local custom_arg = opts.args:match("^custom%s+(.+)$") ---@type string

			api.open_custom_tab(custom_arg)
		else
			require("curl.api").open_curl_tab()
		end
	end, {
		nargs = "*", -- This allows any number of arguments
		complete = function(ArgLead, CmdLine, CursorPos)
			if CmdLine:match("^CurlOpen custom") then
				return {}
			end
			if ArgLead == "" or ArgLead:match("^c") then
				return { "global", "custom" }
			elseif ArgLead:match("^custom%s*") then
				return { "custom " }
			end
			return {}
		end,
		desc = "Open tab for curl.nvim (use 'global' for global scope, or 'custom <arg>' for custom argument)",
	})
end

local create_filetype = function()
	vim.filetype.add({
		extension = {
			curl = "curl",
		},
	})
end
function M.setup(opts)
	create_curl_open()

	create_filetype()

	vim.api.nvim_create_user_command("CurlClose", function()
		require("curl.api").close_curl_tab()
	end, { desc = "Close tab for curl.nvim" })

	vim.api.nvim_set_hl(0, "CurlCommandHighlight", {
		link = "Visual",
	})

	require("curl.config").setup(opts)
end

return setmetatable(M, {
	__index = function(_, k)
		return require("curl.api")[k]
	end,
})

local M = {}

local api = require("curl.api")

local function extract_collection_name(pattern, args)
	return args:match(pattern)
end

local create_curl_open = function()
	vim.api.nvim_create_user_command("CurlOpen", function(opts)
		local args = opts.args ---@type string
		if args == "global" then
			api.open_global_tab()
		elseif args:match("^collection global%s+") then
			local collection_arg = extract_collection_name("^collection global%s+(.+)$", args) ---@type string
			api.open_global_collection(collection_arg)
		elseif args:match("^collection scoped%s+") then
			local collection_arg = extract_collection_name("^collection scoped%s+(.+)$", args) ---@type string
			api.open_scoped_collection(collection_arg)
		elseif args:match("^collection%s+") then
			local collection_arg = extract_collection_name("^collection%s+(.+)$", args) ---@type string
			api.open_collection_tab(collection_arg)
		else
			api.open_curl_tab()
		end
	end, {
		nargs = "*", -- This allows any number of arguments
		complete = function(ArgLead, CmdLine, CursorPos)
			-- No arguments
			if CmdLine:match("^CurlOpen%s$") then
				return { "global", "collection" }
			end

			-- Custom global
			if CmdLine:match("^CurlOpen collection global%s*") then
				-- TODO: print global customs
				return {}
			end

			-- Custom scoped
			if CmdLine:match("^CurlOpen collection scoped%s*") then
				-- TODO: print scoped customs
				return {}
			end
			--
			-- Custom
			if CmdLine:match("^CurlOpen collection%s$") then
				return { "global", "scoped" }
			end
			return {}
		end,
		desc = "Open tab for curl.nvim (use 'global' for global scope, or 'collection global|scoped <arg>' for collection)",
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

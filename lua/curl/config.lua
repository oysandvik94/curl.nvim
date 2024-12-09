---@class curl_config
local default_config = {
	---@type table<string>
	default_flags = {},
	---@type string
	curl_binary = nil,
	---@type "tab"|"split"|"vsplit"
	open_with = "tab", -- tab or (v)split
	---@type table<'execute_curl', string>
	mappings = {
		execute_curl = "<CR>",
	},
}

local mod = {
	config = default_config,
}

function mod.setup(opts)
	mod.config = vim.tbl_deep_extend("force", default_config, opts or {})
	return mod.config
end

---@param key? string
function mod.get(key)
	if key then
		return mod.config[key]
	end

	return mod.config
end

function mod.set(key, value)
	mod.config[key] = value
end

return mod

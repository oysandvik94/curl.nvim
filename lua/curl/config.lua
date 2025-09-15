---@class curl_config
local default_config = {
	---@type table<string>
	default_flags = {},
	---@type integer | nil
	show_request_duration_limit = nil, -- show elapsed time if request duration exceeds this limit; don't show if nil
	---@type string
	curl_binary = nil,
	---@type "tab"|"split"|"vsplit"|"buffer"
	open_with = "tab", -- tab or (v)split or buffer
	---@type "vertical"|"horizontal"
	output_split_direction = "vertical", -- how to split the output buffer
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

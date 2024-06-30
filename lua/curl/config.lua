---@class curl_config
local default_config = {
	---@type table<'execute_curl', false|string>
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

return mod

local M = {}

function M.setup(_)
	vim.api.nvim_create_user_command("Curl", function()
		require("curl.api").open_curl_tab()
	end, {})
end

return setmetatable(M, {
	__index = function(_, k)
		return require("curl.api")[k]
	end,
})

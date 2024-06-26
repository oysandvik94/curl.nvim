local M = {}

function M.setup(opts)
	require("trouble.config").setup(opts)
	vim.api.nvim_create_user_command("Curl", function()
		require("langeoys.utils.rest").open_curl_tab()
	end, {})
end

return setmetatable(M, {
	__index = function(_, k)
		return require("curl.api")[k]
	end,
})

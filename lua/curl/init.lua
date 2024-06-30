local M = {}

function M.setup(opts)
	vim.api.nvim_create_user_command("CurlOpen", function()
		require("curl.api").open_curl_tab()
	end, { desc = "Open tab for curl.nvim" })

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

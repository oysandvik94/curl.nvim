#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

vim.cmd("filetype plugin on")
-- Setup lazy.nvim
require("lazy.minit").busted({
	spec = {
		dir = vim.uv.cwd(),
		config = true,
		dependencies = { "nvim-lua/plenary.nvim" },
		"nvim-treesitter/nvim-treesitter",
	},
})

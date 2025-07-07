return {
	"neanias/everforest-nvim",
	"neovim/nvim-lspconfig",
	"cohama/lexima.vim",
	"DarthMoomancer/Polydev",
	{
		"saghen/blink.cmp",
		version = "v1.*",
		opts = {}
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				highlight = { enable = true },
				indent = { enable = true }
			})
		end
	}
}

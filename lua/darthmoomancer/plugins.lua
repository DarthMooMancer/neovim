return {
	"neovim/nvim-lspconfig",
	"ibhagwan/fzf-lua",
	"rafamadriz/friendly-snippets",
	"neanias/everforest-nvim",
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

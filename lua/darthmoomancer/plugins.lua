local lualine = {
    normal   = {
	a = { fg = "#1E2326", bg = "#A7C080" },
	b = { fg = "#D3C6AA", bg = "none" },
	c = { fg = "#D3C6AA", bg = "none" },
    },
    insert   = {
	a = { fg = "#1E2326", bg = "#D3C6AA" },
	b = { fg = "#D3C6AA", bg = "none" },
	c = { fg = "#D3C6AA", bg = "none" },
    },
    visual   = {
	a = { fg = "#1E2326", bg = "#E67E80" },
	b = { fg = "#D3C6AA", bg = "none" },
	c = { fg = "#D3C6AA", bg = "none" },
    },
    command  = {
	a = { fg = "#1E2326", bg = "#83C092" },
	b = { fg = "#D3C6AA", bg = "none" },
	c = { fg = "#D3C6AA", bg = "none" },
    },
    terminal = {
	a = { fg = "#1E2326", bg = "none" },
	b = { fg = "#D3C6AA", bg = "none" },
	c = { fg = "#D3C6AA", bg = "none" },

    },
    inactive = {
	a = { fg = "#1E2326", bg = "none" },
	b = { fg = "#D3C6AA", bg = "none" },
	c = { fg = "#D3C6AA", bg = "none" },
    }
}

return {
    { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
    { "neovim/nvim-lspconfig", event = "BufReadPost" },
    { "nvim-lualine/lualine.nvim",
	opts = {
	    options = {
		theme = lualine,
		component_separators = "",
		section_separators = { left = "", right = "" },
	    },
	    sections = {
		lualine_y = { "filename" },
		lualine_c = {},
		lualine_x = {},
	    },
	}
    },
    {
	"neanias/everforest-nvim",
	config = function()
	    require("everforest").setup({
		transparent_background_level = 2,
	    })
	    vim.defer_fn(function()
		vim.cmd.colorscheme('everforest')
	    end, 10)
	end
    },
    {
	"ibhagwan/fzf-lua", event = "VeryLazy",
	dependencies = {
	    { "nvim-tree/nvim-web-devicons", lazy = true },
	},
	opts = {
	    fzf_opts = {
		["--pointer"] = " ",
	    }
	}
    },
    {
	dir = "~/personal/Projects/Lua/Polydev",
	dependencies = {
	    { "MunifTanjim/nui.nvim", lazy = true },
	},
	opts = {}
    },
    {
	dir = "~/.local/share/nvim/lazy/lazydev.nvim", ft = "lua", -- Local to fix deprecated errors as folke won't update
	opts = {
	    library = {
		{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
	    },
	},
    },
    {
	"nvim-treesitter/nvim-treesitter", build = ':TSUpdate',
	event = "VeryLazy",
	branch = 'master',
	config = function ()
	    require("nvim-treesitter.configs").setup {
		highlight = { enable = true },
		indent = { enable = true }
	    }
	end
    },
    {
	"saghen/blink.cmp", tag = "v1.3.0", event = "InsertEnter",
	dependencies = { "rafamadriz/friendly-snippets" },
	opts = {
	    signature = { enabled = true },
	    completion = {
		menu = {
		    draw = {
			columns = {
			    { "label", "label_description" , "kind", gap = 1 }
			}
		    }
		},
		documentation = {
		    auto_show = true,
		}
	    },
	}
    }
}

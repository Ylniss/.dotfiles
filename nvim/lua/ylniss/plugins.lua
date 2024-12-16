-- Install `lazy.nvim` plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- Greetings dashboard screen
	{
		"goolord/alpha-nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},

	-- Git related plugins
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",

	-- Adds git related signs, as well as utilities for managing changes
	"lewis6991/gitsigns.nvim",

	{ -- Tree file explorer
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
	},

	{ -- LSP Configuration & Plugins
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Useful status updates for LSP
			{ "j-hui/fidget.nvim", opts = {} },

			-- Additional lua configuration, makes nvim stuff amazing!
			"folke/neodev.nvim",
		},
	},

	{ -- LSP UI improvements
		"nvimdev/lspsaga.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
	},

	-- Show diagnostic messages in separate window
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},

	-- Formatter
	"stevearc/conform.nvim",
	"mfussenegger/nvim-lint",

	{ -- Autocompletion
		"hrsh7th/nvim-cmp",
		dependencies = {
			-- Snippet Engine & its associated nvim-cmp source
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",

			-- Adds LSP completion capabilities
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",

			-- Adds a number of user-friendly snippets
			"rafamadriz/friendly-snippets",
		},
	},

	-- Smart splits navigation with terminal
	{ "mrjones2014/smart-splits.nvim" },

	{ -- Friendly cmdline
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {},
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
	},

	{ -- Add autopaired brackets
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},

	{ -- Surround text with brackets etc.
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},

	-- Show pending keybinds.
	{ "folke/which-key.nvim", opts = {} },

	-- Set colorscheme
	{ "rebelot/kanagawa.nvim", name = "kanagawa", priority = 1000 },

	{ -- Set lualine as statusline
		"nvim-lualine/lualine.nvim",
		opts = {
			options = {
				icons_enabled = false,
				theme = "kanagawa",
				component_separators = "|",
				section_separators = "",
			},
		},
	},

	-- Add indentation guides even on blank lines
	{ "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

	-- "gc" to comment visual regions/lines
	{ "numToStr/Comment.nvim", opts = {} },

	-- Fuzzy Finder (files, lsp, etc)
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		load_on_start = true,
	},

	{
		-- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nushell/tree-sitter-nu",
		},
		build = ":TSUpdate",
	},

	-- Change color of all words under cursor
	"RRethy/vim-illuminate",

	-- Color codes colorizer
	"uga-rosa/ccc.nvim",
}, {})

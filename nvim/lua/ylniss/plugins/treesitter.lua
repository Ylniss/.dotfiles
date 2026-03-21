-- ========================================================
-- Treesitter
-- Syntax highlighting and code parsing
-- ========================================================
return {
	"nvim-treesitter/nvim-treesitter",
	event = "VeryLazy",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		"nushell/tree-sitter-nu",
	},
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"jsonc",
				"dockerfile",
				"terraform",
				"vimdoc",
				"vim",
				"lua",
				"bash",
				"nu",
				"sql",
				"markdown",
				"toml",
				"markdown_inline",
				"gitignore",
			},
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
		})
	end,
}

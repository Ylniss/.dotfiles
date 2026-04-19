-- ========================================================
-- Treesitter
-- Syntax highlighting and code parsing
-- ========================================================
return {
	"nvim-treesitter/nvim-treesitter",
	event = "VeryLazy",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
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
				"c_sharp",
				"nix",
			},
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
		})

		-- Map markdown fence names to parser names where they differ.
		vim.treesitter.language.register("c_sharp", { "csharp", "cs" })
	end,
}

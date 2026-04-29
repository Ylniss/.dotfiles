-- ========================================================
-- markview.nvim
-- Inline markdown rendering with hybrid (editable) preview
-- ========================================================
return {
	"OXY2DEV/markview.nvim",
	ft = "markdown",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	opts = {
		preview = {
			enable_hybrid_mode = true,
			hybrid_modes = { "n", "i" },
		},
	},
}

-- ========================================================
-- yazi.nvim
-- Floating Yazi file manager
-- ========================================================
return {
	"mikavilpas/yazi.nvim",
	version = "*",
	keys = {
		{ "<leader>e", "<cmd>Yazi<CR>", desc = "open yazi at current file" },
		{ "<leader>E", "<cmd>Yazi cwd<CR>", desc = "open yazi at cwd" },
	},
	opts = {},
}

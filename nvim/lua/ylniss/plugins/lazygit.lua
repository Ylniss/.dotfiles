-- ========================================================
-- LazyGit
-- Floating lazygit terminal
-- ========================================================
return {
	"kdheepak/lazygit.nvim",
	cmd = { "LazyGit", "LazyGitCurrentFile", "LazyGitFilter" },
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = {
		{ "<leader>gi", "<cmd>LazyGit<cr>", desc = "lazygit" },
	},
}

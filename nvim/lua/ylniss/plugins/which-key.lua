-- ========================================================
-- Which-key
-- Show pending keybinding hints in a popup
-- ========================================================
return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		spec = {
			{ "<leader>e", group = "explore" },
			{ "<leader>g", group = "git", mode = { "n", "v" } },
			{ "<leader>gh", group = "git hunks", mode = { "n", "v" } },
			{ "<leader>s", group = "search" },

			{ "<leader>", group = "VISUAL <leader>", mode = "v" },
		},
	},
}

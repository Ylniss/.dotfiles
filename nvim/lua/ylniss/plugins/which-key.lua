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
			{ "<leader>g", group = "git" },
			{ "<leader>gh", group = "git hunks" },
			{ "<leader>s", group = "search" },

			{ "<leader>", group = "VISUAL <leader>", mode = "v" },
			{ "<leader>h", desc = "git hunk", mode = "v" },
		},
	},
}

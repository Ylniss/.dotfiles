-- ========================================================
-- Smart-splits
-- Window resize and navigation across terminal splits
-- ========================================================
return {
	"mrjones2014/smart-splits.nvim",
	event = "VeryLazy",
	config = function()
		local ss = require("smart-splits")
		ss.setup({
			at_edge = "stop",
		})
		vim.keymap.set("n", "<A-h>", ss.resize_left, { desc = "resize window left" })
		vim.keymap.set("n", "<A-j>", ss.resize_down, { desc = "resize window down" })
		vim.keymap.set("n", "<A-k>", ss.resize_up, { desc = "resize window up" })
		vim.keymap.set("n", "<A-l>", ss.resize_right, { desc = "resize window right" })
		vim.keymap.set("n", "<C-h>", ss.move_cursor_left, { desc = "move cursor left" })
		vim.keymap.set("n", "<C-j>", ss.move_cursor_down, { desc = "move cursor down" })
		vim.keymap.set("n", "<C-k>", ss.move_cursor_up, { desc = "move cursor up" })
		vim.keymap.set("n", "<C-l>", ss.move_cursor_right, { desc = "move cursor right" })
	end,
}

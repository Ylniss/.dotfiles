-- ========================================================
-- Diffview
-- Tabpage-based diff viewer and git status
-- ========================================================
return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
	keys = {
		{
			"<leader>gs",
			function()
				local lib = require("diffview.lib")
				if lib.get_current_view() then
					vim.cmd.DiffviewClose()
				else
					vim.cmd.DiffviewOpen()
				end
			end,
			desc = "git status",
		},
		{ "<leader>gl", "<cmd>DiffviewFileHistory %<CR>", desc = "git log (file)" },
	},
	opts = {},
}

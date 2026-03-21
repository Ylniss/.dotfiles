-- ========================================================
-- Gitsigns
-- Git gutter signs and hunk operations
-- ========================================================
return {
	"lewis6991/gitsigns.nvim",
	event = "BufReadPre",
	opts = {
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function keymap(mode, l, r, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end

			keymap("v", "<leader>ghs", function()
				gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, { desc = "stage git hunk" })
			keymap("v", "<leader>ghr", function()
				gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, { desc = "reset git hunk" })
			keymap("n", "<leader>ghs", gs.stage_hunk, { desc = "git stage hunk" })
			keymap("n", "<leader>ghr", gs.reset_hunk, { desc = "git reset hunk" })
			keymap("n", "<leader>ghS", gs.stage_buffer, { desc = "git Stage buffer" })
			keymap("n", "<leader>ghu", gs.undo_stage_hunk, { desc = "undo stage hunk" })
			keymap("n", "<leader>gR", gs.reset_buffer, { desc = "git Reset buffer" })
			keymap("n", "<leader>gp", gs.preview_hunk, { desc = "preview git hunk" })
			keymap("n", "<leader>gb", function()
				gs.blame_line({ full = false })
			end, { desc = "git blame line" })
			keymap("n", "<leader>gd", gs.diffthis, { desc = "git diff against index" })
			keymap("n", "<leader>gD", function()
				gs.diffthis("~")
			end, { desc = "git diff against last commit" })
			keymap("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "toggle git blame line" })
			keymap("n", "<leader>gr", gs.toggle_deleted, { desc = "toggle git show removed" })
		end,
	},
}

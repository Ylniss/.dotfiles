-- ========================================================
-- obsidian.nvim
-- Navigate Obsidian vaults (wikilinks, backlinks, completion)
-- ========================================================
return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	ft = "markdown",
	cmd = { "Obsidian" },
	opts = {
		legacy_commands = false,
		workspaces = {
			{
				name = "knowtes",
				path = "~/stuff/knowtes",
			},
		},
		picker = { name = "fzf-lua" },
		-- Keep the note buffer plain. md-render.nvim shows the rendered view in a separate buffer.
		ui = { enable = false },
		frontmatter = { enabled = false },
		checkbox = { order = { " ", "x" } },
		callbacks = {
			enter_note = function(_)
				-- Set our mappings before deleting the defaults, so a failed delete doesn't skip them.
				local actions = require("obsidian.actions")
				local function nmap(lhs, rhs, desc)
					vim.keymap.set("n", lhs, rhs, { buffer = true, desc = "obsidian: " .. desc })
				end

				nmap("gd", actions.follow_link, "follow link under cursor")
				nmap("gb", "<cmd>Obsidian backlinks<CR>", "show backlinks")
				nmap("<leader>sf", "<cmd>Obsidian quick_switch<CR>", "fuzzy-find notes (overrides fzf-lua)")
				nmap("<leader>sg", "<cmd>Obsidian search<CR>", "grep vault (overrides fzf-lua)")
				nmap("<leader>t", actions.toggle_checkbox, "toggle checkbox")

				-- Delete plugin defaults that override our <CR> or make ]/[ wait for timeout.
				for _, lhs in ipairs({ "<CR>", "]o", "[o" }) do
					vim.keymap.del("n", lhs, { buffer = true })
				end
			end,
		},
	},
}

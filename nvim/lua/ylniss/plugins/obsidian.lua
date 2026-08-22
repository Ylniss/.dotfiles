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
				-- Fix letter case on Windows ("stuff" -> "Stuff") so the workspace matches.
				path = vim.uv.fs_realpath(vim.fn.expand("~/stuff/knowtes")) or vim.fn.expand("~/stuff/knowtes"),
			},
		},
		picker = { name = "fzf-lua" },
		-- markview.nvim renders markdown (and sets conceallevel); don't double-render.
		ui = { enable = false },
		frontmatter = { enabled = false },
		checkbox = { order = { " ", "x" } },
		callbacks = {
			enter_note = function(_)
				-- Set our mappings before deleting the defaults, so a failed delete doesn't skip them.
				local actions = require("obsidian.actions")
				local api = require("obsidian.api")
				local function nmap(lhs, rhs, desc)
					vim.keymap.set("n", lhs, rhs, { buffer = true, desc = "obsidian: " .. desc })
				end

				nmap("gd", function()
					-- actions.follow_link won't find the link under the cursor; pass it in.
					local link = api.cursor_link()
					if link then
						actions.follow_link(link)
					end
				end, "follow link under cursor")
				nmap("gb", "<cmd>Obsidian backlinks<CR>", "show backlinks")
				nmap("<leader>sf", "<cmd>Obsidian quick_switch<CR>", "fuzzy-find notes (overrides fzf-lua)")
				nmap("<leader>sg", "<cmd>Obsidian search<CR>", "grep vault (overrides fzf-lua)")
				nmap("<leader>t", actions.toggle_checkbox, "toggle checkbox")

				-- Drop plugin defaults that shadow our <CR> or delay ]/[.
				-- pcall: defaults vary by buffer state; skip if not registered.
				for _, lhs in ipairs({ "<CR>", "]o", "[o", "]l", "[l" }) do
					pcall(vim.keymap.del, "n", lhs, { buffer = true })
				end
			end,
		},
	},
}

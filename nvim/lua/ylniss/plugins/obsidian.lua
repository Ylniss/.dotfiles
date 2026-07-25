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
				-- Canonicalize case on Windows ("stuff" -> "Stuff") for workspace match.
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
				-- Set before del so a failed del doesn't skip our mappings.
				local actions = require("obsidian.actions")
				local api = require("obsidian.api")
				vim.keymap.set("n", "gd", function()
					-- actions.follow_link doesn't resolve nil → cursor link; do it ourselves.
					local link = api.cursor_link()
					if link then
						actions.follow_link(link)
					end
				end, { buffer = true, desc = "obsidian: follow link under cursor" })
				vim.keymap.set(
					"n",
					"gb",
					"<cmd>Obsidian backlinks<CR>",
					{ buffer = true, desc = "obsidian: show backlinks" }
				)
				vim.keymap.set(
					"n",
					"<leader>sf",
					"<cmd>Obsidian quick_switch<CR>",
					{ buffer = true, desc = "obsidian: fuzzy-find notes (overrides fzf-lua)" }
				)
				vim.keymap.set(
					"n",
					"<leader>sg",
					"<cmd>Obsidian search<CR>",
					{ buffer = true, desc = "obsidian: grep vault (overrides fzf-lua)" }
				)
				vim.keymap.set(
					"n",
					"<leader>t",
					actions.toggle_checkbox,
					{ buffer = true, desc = "obsidian: toggle checkbox" }
				)

				-- Drop plugin defaults that shadow our <CR> or delay ]/[.
				-- pcall: defaults vary by buffer state; skip if not registered.
				for _, lhs in ipairs({ "<CR>", "]o", "[o", "]l", "[l" }) do
					pcall(vim.keymap.del, "n", lhs, { buffer = true })
				end
			end,
		},
	},
}

-- ========================================================
-- obsidian.nvim
-- Navigate the Markdown knowledge base (links, backlinks, completion)
-- ========================================================
local function notes_by_tags()
	local fzf = require("fzf-lua")
	local Note = require("obsidian.note")
	local separator = require("fzf-lua.utils").nbsp
	local root = tostring(Obsidian.dir)
	local entries = vim.iter(vim.fn.globpath(root, "*.md", false, true))
		:map(function(path)
			return Note.from_file(path)
		end)
		:filter(function(note)
			return #note.tags > 0
		end)
		:map(function(note)
			return table.concat({
				note.path.name .. ":1:1:",
				note.path.stem,
				table.concat(note.tags, ", "),
				note.metadata.description or "",
			}, separator)
		end)
		:totable()
	table.sort(entries)

	fzf.fzf_exec(entries, {
		cwd = root,
		prompt = "Note tags> ",
		previewer = "builtin",
		formatter = false,
		actions = fzf.defaults.actions.files,
		fzf_opts = {
			["--delimiter"] = separator,
			["--with-nth"] = "2..",
			-- --nth counts displayed columns, so 2 is the tags.
			["--nth"] = "2",
			["--multi"] = true,
		},
	})
end

return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	ft = "markdown",
	cmd = { "Obsidian" },
	keys = {
		{ "<leader>sn", notes_by_tags, desc = "search notes by YAML tags" },
	},
	opts = {
		legacy_commands = false,
		workspaces = {
			{
				name = "knowtes",
				path = "~/stuff/knowtes",
			},
		},
		picker = { name = "fzf-lua" },
		link = { style = "markdown" },
		-- Keep the note buffer plain. md-render.nvim shows the rendered view in a separate buffer.
		ui = { enable = false },
		frontmatter = { enabled = false },
		checkbox = { order = { " ", "x" } },
		callbacks = {
			post_setup = function()
				local picker = require("obsidian.picker.fzf")
				local original_select = picker.select
				picker.select = function(values, opts, on_choice)
					opts = vim.tbl_extend("force", {}, opts or {})
					local format_item = opts.format_item or require("obsidian.picker.util").make_display
					-- fzf trims trailing whitespace, breaking Obsidian's lookup by display text.
					opts.format_item = function(value)
						return (format_item(value):gsub("%s+$", ""))
					end
					return original_select(values, opts, on_choice)
				end
			end,
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

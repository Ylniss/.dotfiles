-- ========================================================
-- fzf-lua
-- Fuzzy finder for files, grep, LSP, and more
-- ========================================================
return {
	"ibhagwan/fzf-lua",
	event = "VeryLazy",
	config = function()
		local fzf = require("fzf-lua")
		-- With file icons, fzf-lua defaults to `--nth -1..` to skip the icon field when matching.
		-- On Windows, a process with `-1..` in its command line starts 0.2-2 s late, most likely from a Defender scan.
		-- `-1` selects the same field.
		local nth_skip_icon = { ["--nth"] = "-1" }
		fzf.setup({
			-- An absolute path skips the PATH lookups for fzf on every picker start (~50 ms on Windows).
			fzf_bin = vim.fn.exepath("fzf"),
			files = {
				fd_opts = "--type f --hidden --exclude .git",
				fzf_opts = nth_skip_icon,
			},
			git = { files = { fzf_opts = nth_skip_icon } },
			oldfiles = { fzf_opts = nth_skip_icon },
			keymap = { fzf = { ["ctrl-q"] = "select-all+accept" } },
			defaults = { formatter = "path.filename_first" },
		})

		local function git_root_or_cwd()
			local root = vim.fs.root(0, ".git")
			if not root then
				vim.notify("Not a git repository. Searching on current working directory", vim.log.levels.WARN)
				return vim.fn.getcwd()
			end
			return root
		end

		local function live_grep_git_root()
			fzf.live_grep({ cwd = git_root_or_cwd() })
		end

		local function live_grep_open_files()
			local paths = vim.iter(vim.api.nvim_list_bufs())
				:filter(vim.api.nvim_buf_is_loaded)
				:map(vim.api.nvim_buf_get_name)
				:filter(function(name)
					return name ~= ""
				end)
				:totable()
			fzf.live_grep({ search_paths = paths })
		end

		local function search_diagnostics()
			local fzf_utils = require("fzf-lua.utils")
			local actions = require("fzf-lua.actions")
			local nbsp = fzf_utils.nbsp

			local diags = vim.diagnostic.get(nil)
			table.sort(diags, function(a, b)
				if a.severity ~= b.severity then
					return a.severity < b.severity
				end
				return a.lnum < b.lnum
			end)

			local severity_styles = {
				[1] = { icon = "E", hl = "DiagnosticError" },
				[2] = { icon = "W", hl = "DiagnosticWarn" },
				[3] = { icon = "I", hl = "DiagnosticInfo" },
				[4] = { icon = "H", hl = "DiagnosticHint" },
			}

			local entries = {}
			for _, diag in ipairs(diags) do
				local bufname = vim.api.nvim_buf_get_name(diag.bufnr)
				if bufname == "" then
					goto continue
				end
				local style = severity_styles[diag.severity]

				local rel_path = vim.fn.fnamemodify(bufname, ":~:.")
				local loc = string.format("%s:%d:%d", rel_path, diag.lnum + 1, diag.col + 1)
				local msg = diag.message:match("^[^\n]+") or diag.message

				local icon = fzf_utils.ansi_from_hl(style.hl, style.icon)
				local dim_loc = fzf_utils.ansi_from_hl("Comment", loc)

				-- entry_to_file() reads the location from the first nbsp field that matches :%d+:.
				-- Field 1 holds the location for preview and actions. `--with-nth` hides field 1.
				table.insert(
					entries,
					table.concat({
						loc .. ":",
						icon,
						string.format("%s  %s", msg, dim_loc),
					}, nbsp)
				)

				::continue::
			end

			if #entries == 0 then
				vim.notify("No diagnostics", vim.log.levels.INFO)
				return
			end

			fzf.fzf_exec(entries, {
				cwd = vim.fn.getcwd(),
				actions = {
					["enter"] = actions.file_edit_or_qf,
					["ctrl-s"] = actions.file_split,
					["ctrl-v"] = actions.file_vsplit,
					["ctrl-t"] = actions.file_tabedit,
				},
				previewer = "builtin",
				fzf_opts = {
					["--delimiter"] = nbsp,
					["--with-nth"] = "2..",
					["--multi"] = true,
					["--wrap"] = true,
				},
			})
		end

		vim.keymap.set("n", "<leader><space>", fzf.buffers, { desc = "find existing buffers" })
		vim.keymap.set("n", "<leader>?", fzf.oldfiles, { desc = "find recently opened files" })
		vim.keymap.set("n", "<leader>/", fzf.grep_curbuf, { desc = "fuzzily search in current buffer" })
		vim.keymap.set("n", "<leader>s/", live_grep_open_files, { desc = "search in Open Files" })
		vim.keymap.set("n", "<leader>st", fzf.builtin, { desc = "select fzf-lua picker" })
		vim.keymap.set("n", "<leader>ss", fzf.git_files, { desc = "search git files" })
		vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "search files" })
		vim.keymap.set("n", "<leader>sp", function()
			fzf.files({ cwd = "~/stuff/repo/" })
		end, { desc = "search repo" })
		vim.keymap.set("n", "<leader>sh", fzf.help_tags, { desc = "search help" })
		vim.keymap.set("n", "<leader>sw", fzf.grep_cword, { desc = "search current word" })
		vim.keymap.set("n", "<leader>sg", live_grep_git_root, { desc = "search by grep on git root" })
		vim.keymap.set("n", "<leader>sd", search_diagnostics, { desc = "search diagnostics" })
		vim.keymap.set("n", "<leader>sb", fzf.marks, { desc = "search bookmarks" })
		vim.keymap.set("n", "<leader>sk", fzf.keymaps, { desc = "search keymaps" })
		vim.keymap.set("n", "<leader>sr", fzf.resume, { desc = "search resume" })
	end,
}

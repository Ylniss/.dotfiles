-- ========================================================
-- fzf-lua
-- Fuzzy finder for files, grep, LSP, and more
-- ========================================================
return {
	"ibhagwan/fzf-lua",
	event = "VeryLazy",
	config = function()
		local fzf = require("fzf-lua")
		fzf.setup({
			files = {
				fd_opts = "--type f --hidden --exclude .git",
				git_icons = false,
			},
			grep = {
				git_icons = false,
			},
			keymap = { fzf = { ["ctrl-q"] = "select-all+accept" } },
			defaults = { formatter = "path.filename_first" },
		})

		local function find_git_root()
			local buf_path = vim.api.nvim_buf_get_name(0)
			local start_dir = buf_path == "" and vim.fn.getcwd() or vim.fn.fnamemodify(buf_path, ":h")
			local git_dir = vim.fs.find(".git", { upward = true, path = start_dir })[1]
			if not git_dir then
				vim.notify("Not a git repository. Searching on current working directory", vim.log.levels.WARN)
				return vim.fn.getcwd()
			end
			return vim.fs.dirname(git_dir)
		end

		local function live_grep_git_root()
			fzf.live_grep({ cwd = find_git_root() })
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
		vim.keymap.set("n", "<leader>sd", function()
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
				if not style then
					goto continue
				end

				local rel_path = vim.fn.fnamemodify(bufname, ":~:.")
				local msg = diag.message:match("^[^\n]+") or diag.message
				local lnum = diag.lnum + 1
				local col = diag.col + 1

				local icon = fzf_utils.ansi_from_hl(style.hl, style.icon)
				local dim_path = fzf_utils.ansi_from_hl("Comment", string.format("%s:%d:%d", rel_path, lnum, col))

				-- entry_to_file() splits by nbsp, finds first part matching :%d+:
				-- Field 1 (hidden): path:lnum:col: for parsing/preview/actions
				-- Field 2: severity icon
				-- Field 3: message + dimmed path
				table.insert(
					entries,
					table.concat({
						string.format("%s:%d:%d:", rel_path, lnum, col),
						icon,
						string.format("%s  %s", msg, dim_path),
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
					["default"] = actions.file_edit_or_qf,
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
		end, { desc = "search diagnostics" })
		vim.keymap.set("n", "<leader>sb", fzf.marks, { desc = "search bookmarks" })
		vim.keymap.set("n", "<leader>sk", fzf.keymaps, { desc = "search keymaps" })
		vim.keymap.set("n", "<leader>sr", fzf.resume, { desc = "search resume" })
	end,
}

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
			files = { fd_opts = "--type f --hidden --exclude .git" },
			keymap = { fzf = { ["ctrl-q"] = "select-all+accept" } },
			defaults = { formatter = "path.filename_first" },
		})

		local function find_git_root()
			local current_file = vim.api.nvim_buf_get_name(0)
			local current_dir
			local cwd = vim.fn.getcwd()
			if current_file == "" then
				current_dir = cwd
			else
				current_dir = vim.fn.fnamemodify(current_file, ":h")
			end
			local git_root = vim.fn.systemlist(
				"git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel"
			)[1]
			if vim.v.shell_error ~= 0 then
				print("Not a git repository. Searching on current working directory")
				return cwd
			end
			return git_root
		end

		local function live_grep_git_root()
			local git_root = find_git_root()
			if git_root then
				fzf.live_grep({ cwd = git_root })
			end
		end

		local function live_grep_open_files()
			local bufnrs = vim.api.nvim_list_bufs()
			local paths = {}
			for _, bufnr in ipairs(bufnrs) do
				if vim.api.nvim_buf_is_loaded(bufnr) then
					local name = vim.api.nvim_buf_get_name(bufnr)
					if name ~= "" then
						table.insert(paths, name)
					end
				end
			end
			fzf.live_grep({ search_paths = paths })
		end

		vim.keymap.set("n", "<leader><space>", fzf.buffers, { desc = "find existing buffers" })
		vim.keymap.set("n", "<leader>?", fzf.oldfiles, { desc = "find recently opened files" })
		vim.keymap.set("n", "<leader>/", fzf.grep_curbuf, { desc = "fuzzily search in current buffer" })
		vim.keymap.set("n", "<leader>s/", live_grep_open_files, { desc = "search in Open Files" })
		vim.keymap.set("n", "<leader>st", fzf.builtin, { desc = "search select fzf-lua" })
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
				if a.severity ~= b.severity then return a.severity < b.severity end
				return a.lnum < b.lnum
			end)

			local sev_map = {
				[1] = { icon = "E", hl = "DiagnosticError" },
				[2] = { icon = "W", hl = "DiagnosticWarn" },
				[3] = { icon = "I", hl = "DiagnosticInfo" },
				[4] = { icon = "H", hl = "DiagnosticHint" },
			}

			local entries = {}
			for _, d in ipairs(diags) do
				local bufname = vim.api.nvim_buf_get_name(d.bufnr)
				if bufname == "" then goto continue end
				local s = sev_map[d.severity]
				if not s then goto continue end

				local rel_path = vim.fn.fnamemodify(bufname, ":~:.")
				local msg = d.message:match("^[^\n]+") or d.message
				local lnum = d.lnum + 1
				local col = d.col + 1

				local icon = fzf_utils.ansi_from_hl(s.hl, s.icon)
				local dim_path = fzf_utils.ansi_from_hl("Comment",
					string.format("%s:%d:%d", rel_path, lnum, col))

				-- entry_to_file() splits by nbsp, finds first part matching :%d+:
				-- Field 1 (hidden): path:lnum:col: for parsing/preview/actions
				-- Field 2: severity icon
				-- Field 3: message + dimmed path
				table.insert(entries, table.concat({
					string.format("%s:%d:%d:", rel_path, lnum, col),
					icon,
					string.format("%s  %s", msg, dim_path),
				}, nbsp))

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

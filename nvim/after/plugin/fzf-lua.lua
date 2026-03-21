local fzf = require("fzf-lua")

fzf.setup({
	files = {
		fd_opts = "--type f --hidden --exclude .git",
	},
	keymap = {
		fzf = {
			["ctrl-q"] = "select-all+accept",
		},
	},
})

-- Find the git root directory based on the current buffer's path
local function find_git_root()
	-- Use the current buffer's path as the starting point for the git search
	local current_file = vim.api.nvim_buf_get_name(0)
	local current_dir
	local cwd = vim.fn.getcwd()
	-- If the buffer is not associated with a file, return nil
	if current_file == "" then
		current_dir = cwd
	else
		-- Extract the directory from the current file's path
		current_dir = vim.fn.fnamemodify(current_file, ":h")
	end

	-- Find the Git root directory from the current file's path
	local git_root =
		vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
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
	-- Collect paths of all open buffers
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

local function find_files_in_repo()
	fzf.files({ cwd = "~/stuff/repo/" })
end

vim.keymap.set("n", "<leader><space>", fzf.buffers, { desc = "find existing buffers" })
vim.keymap.set("n", "<leader>?", fzf.oldfiles, { desc = "find recently opened files" })
vim.keymap.set("n", "<leader>/", fzf.grep_curbuf, { desc = "fuzzily search in current buffer" })
vim.keymap.set("n", "<leader>s/", live_grep_open_files, { desc = "search in Open Files" })
vim.keymap.set("n", "<leader>st", fzf.builtin, { desc = "search select fzf-lua" })
vim.keymap.set("n", "<leader>ss", fzf.git_files, { desc = "search git files" })
vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "search files" })
vim.keymap.set("n", "<leader>sp", find_files_in_repo, { desc = "search repo" })
vim.keymap.set("n", "<leader>sh", fzf.help_tags, { desc = "search help" })
vim.keymap.set("n", "<leader>sw", fzf.grep_cword, { desc = "search current word" })
vim.keymap.set("n", "<leader>sg", live_grep_git_root, { desc = "search by grep on git root" })
vim.keymap.set("n", "<leader>sd", fzf.diagnostics_workspace, { desc = "search diagnostics" })
vim.keymap.set("n", "<leader>sb", fzf.marks, { desc = "search bookmarks" })
vim.keymap.set("n", "<leader>sr", fzf.resume, { desc = "search resume" })

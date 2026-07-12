-- ================================== Basic navigation ==================================
vim.keymap.set({ "n", "v" }, "Z", "^", { desc = "move to the first character in line" })
vim.keymap.set({ "n", "v" }, "X", "$", { desc = "move to the end of line" })
vim.keymap.set({ "n", "v" }, "<C-b>", "%", { desc = "jump to matching bracket" })
vim.keymap.set({ "n", "v" }, "<CR>", "o<ESC>", { desc = "add new line in normal mode" })
vim.keymap.set({ "n", "v" }, "<leader>n", "<C-6>", { desc = "go back to previous file" })

vim.keymap.set({ "n", "v" }, "<C-d>", "<C-d>zz", { desc = "scroll half screen down" })
vim.keymap.set({ "n", "v" }, "<C-u>", "<C-u>zz", { desc = "scroll half screen up" })

-- ============================= Go to next/previous buffer =============================
vim.keymap.set("n", "]", vim.cmd.bnext, { desc = "go to next buffer" })
vim.keymap.set("n", "[", vim.cmd.bprevious, { desc = "go to previous buffer" })

-- =========================== Reverse paste p and P commands ===========================
vim.keymap.set({ "n", "v" }, "p", "P", { desc = "paste without overwriting clipboard" })
vim.keymap.set({ "n", "v" }, "P", "p", { desc = "paste with overwriting clipboard" })

-- ================================= Move selected code =================================
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- ================= Remove space functions because it is a leader key ==================
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- =============================== Dealing with word wrap ===============================
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- ================================= Window management =================================
vim.keymap.set("n", "<A-Left>", "<C-w>H", { desc = "move window left" })
vim.keymap.set("n", "<A-Right>", "<C-w>L", { desc = "move window right" })
vim.keymap.set("n", "<A-Down>", "<C-w>J", { desc = "move window down" })
vim.keymap.set("n", "<A-Up>", "<C-w>K", { desc = "move window up" })

vim.keymap.set("n", "<leader>v", vim.cmd.vsplit, { desc = "open new vertical split window" })
vim.keymap.set("n", "<leader>h", vim.cmd.split, { desc = "open new horizontal split window" })

-- ======================================= Misc =======================================
vim.keymap.set("v", "<leader>r", '"hy:%s/<C-r>h//gc<left><left><left>', { desc = "find and replace" })

vim.keymap.set("n", "yf", "<cmd>%y<CR>", { noremap = true, desc = "yank whole file" })

vim.keymap.set("n", "<leader>yd", function()
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local diags = vim.diagnostic.get(0, { lnum = lnum })
	if #diags == 0 then
		vim.notify("No diagnostics on this line", vim.log.levels.INFO)
		return
	end
	local msgs = {}
	for _, d in ipairs(diags) do
		table.insert(msgs, d.message)
	end
	vim.fn.setreg("+", table.concat(msgs, "\n"))
end, { desc = "yank diagnostic under cursor to clipboard" })

-- ====================================== Yazi ========================================
vim.keymap.set("n", "<leader>e", "<cmd>Yazi<CR>", { desc = "open yazi at current file" })
vim.keymap.set("n", "<leader>E", "<cmd>Yazi cwd<CR>", { desc = "open yazi at cwd" })

-- ================================= Git actions =================================
vim.keymap.set("n", "<leader>g>", "<cmd>!git push<CR>", { noremap = true, desc = "git push" })
vim.keymap.set("n", "<leader>g<", "<cmd>!git pull<CR>", { noremap = true, desc = "git pull" })

-- Add every changed/untracked file (skip deletions) to the buffer list and open the first.
local function git_status_to_buffers()
	local git_root = vim.fs.root(0, ".git")
	if not git_root then
		vim.notify("Not a git repository", vim.log.levels.WARN)
		return
	end

	local result = vim.system({ "git", "-C", git_root, "status", "--porcelain", "-z" }):wait()
	if result.code ~= 0 then
		vim.notify("git status failed", vim.log.levels.ERROR)
		return
	end
	local output = result.stdout

	local first_bufnr
	local i = 1
	while i <= #output do
		local nul = output:find("\0", i, true)
		if not nul then
			break
		end
		local entry = output:sub(i, nul - 1)
		i = nul + 1

		local x = entry:sub(1, 1)
		local y = entry:sub(2, 2)
		local path = entry:sub(4)

		-- Renames/copies are followed by an extra NUL-terminated old path
		if x == "R" or x == "C" then
			local nul2 = output:find("\0", i, true)
			if nul2 then
				i = nul2 + 1
			end
		end

		if x ~= "D" and y ~= "D" then
			local bufnr = vim.fn.bufadd(vim.fs.joinpath(git_root, path))
			vim.bo[bufnr].buflisted = true
			if not first_bufnr then
				first_bufnr = bufnr
			end
		end
	end

	if not first_bufnr then
		vim.notify("No changed files", vim.log.levels.INFO)
		return
	end

	vim.fn.bufload(first_bufnr)
	vim.api.nvim_set_current_buf(first_bufnr)
end

vim.keymap.set("n", "<leader>gs", git_status_to_buffers, { desc = "add git status files to buffers" })

-- =================================== Commenting ===================================
-- Map both forms: terminals using legacy xterm encoding send 0x1f (<C-_>); terminals
-- using kitty keyboard protocol / CSI u (recent wezterm) send the modern <C-/> form.
for _, lhs in ipairs({ "<C-_>", "<C-/>" }) do
	vim.keymap.set("n", lhs, "gcc", { remap = true, desc = "toggle line comment" })
	vim.keymap.set("v", lhs, "gc", { remap = true, desc = "toggle line comment" })
end

-- ================================= LSP keymaps ==================================
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local bufnr = ev.buf
		local lsp_keymap = function(keys, func, desc)
			if desc then
				desc = "lsp: " .. desc
			end
			vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
		end

		lsp_keymap("<leader>r", vim.lsp.buf.rename, "rename")
		lsp_keymap("<leader>a", vim.lsp.buf.code_action, "code action")

		local fzf = require("fzf-lua")
		lsp_keymap("gD", vim.lsp.buf.declaration, "goto declaration")
		lsp_keymap("gd", fzf.lsp_definitions, "goto definition")
		lsp_keymap("gr", fzf.lsp_references, "goto references")
		lsp_keymap("gI", fzf.lsp_implementations, "goto implementation")
		lsp_keymap("<leader>D", fzf.lsp_typedefs, "type definition")
	end,
})

-- ================================= Markdown keymaps =================================
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(ev)
		local function vmap(lhs, rhs, desc)
			vim.keymap.set("v", lhs, rhs, { buffer = ev.buf, desc = desc })
		end
		vmap("<leader>`", [[c`<C-r>"`<Esc>]], "markdown: surround with backticks")
		vmap("<C-b>", [[c**<C-r>"**<Esc>]], "markdown: bold (**)")
		vmap("<C-i>", [[c*<C-r>"*<Esc>]], "markdown: italic (*)")
	end,
})

-- ========================== Document existing key chains ==========================
local whichKey = require("which-key")
whichKey.add({
	{ "<leader>e", group = "explore" },
	{ "<leader>e_", hidden = true },
	{ "<leader>g", group = "git" },
	{ "<leader>g_", hidden = true },
	{ "<leader>gh", group = "git hunks" },
	{ "<leader>gh_", hidden = true },
	{ "<leader>s", group = "search" },
	{ "<leader>s_", hidden = true },
})

-- Required for visual <leader>hs (hunk stage) to work
whichKey.add({
	{ "<leader>", group = "VISUAL <leader>", mode = "v" },
	{ "<leader>h", desc = "git hunk", mode = "v" },
})

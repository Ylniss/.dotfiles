-- ================================== Basic navigation ==================================
vim.keymap.set({ "n", "v" }, "Z", "^", { desc = "move to the first character in line" })
vim.keymap.set({ "n", "v" }, "X", "$", { desc = "move to the end of line" })
vim.keymap.set({ "n", "v" }, "<C-b>", "%", { desc = "jump to matching bracket" })
vim.keymap.set({ "n", "v" }, "<CR>", "o<ESC>", { desc = "add new line in normal mode" })
vim.keymap.set({ "n", "v" }, "<leader>n", "<C-6>", { desc = "go back to previous file" })

vim.keymap.set({ "n", "v" }, "J", "}", { desc = "move down by 1 paragraph" })
vim.keymap.set({ "n", "v" }, "K", "{", { noremap = true, desc = "move up by 1 paragraph" })
vim.keymap.set({ "n", "v" }, "L", "w", { desc = "move right by 1 word" })
vim.keymap.set({ "n", "v" }, "H", "b", { desc = "move left by 1 word" })

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

-- ===================================== Commands =====================================
local function saveAndClose()
	local status, _ = pcall(vim.cmd.wq)
	if not status then
		vim.cmd.q()
	end
end

vim.keymap.set("n", "<leader>q", saveAndClose, { desc = "save and close window" })
vim.keymap.set("n", "<leader>Q", "<cmd>q!<CR>", { desc = "close window without saving" })
local function smart_save()
	local current_file = vim.fn.expand("%:p")
	if current_file == "" then
		-- File has no name, open command line with saveas and current directory
		local current_dir = vim.fn.expand("%:p:h") .. "/"
		local saveas_cmd = ":saveas " .. current_dir
		vim.api.nvim_feedkeys(saveas_cmd, "n", true)
	else
		-- File already has a name, just write
		vim.cmd.update()
	end
end

vim.keymap.set({ "n", "v" }, "<C-s>", smart_save, { desc = "save file" })
vim.keymap.set({ "n", "v" }, "<C-S-s>", vim.cmd.wa, { noremap = true, desc = "save all changes" })

vim.keymap.set("v", "<leader>r", '"hy:%s/<C-r>h//gc<left><left><left>', { desc = "find and replace" })

vim.keymap.set("n", "yf", "<cmd>%y<CR>", { noremap = true, desc = "yank whole file" })

-- ===================================== NeoTree ======================================
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "open/close explorer" })

-- ================================= Git actions =================================
vim.keymap.set("n", "<leader>g>", "<cmd>!git push<CR>", { noremap = true, desc = "git push" })
vim.keymap.set("n", "<leader>g<", "<cmd>!git pull<CR>", { noremap = true, desc = "git pull" })

-- =================================== Commenting ===================================
vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "toggle line comment" })
vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "toggle line comment" })

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
		lsp_keymap("<leader>k", vim.lsp.buf.hover, "hover")
		lsp_keymap("<C-.>", vim.lsp.buf.code_action, "code action")
		lsp_keymap("<leader>a", vim.lsp.buf.code_action, "code action")

		local fzf = require("fzf-lua")
		lsp_keymap("gD", vim.lsp.buf.declaration, "goto declaration")
		lsp_keymap("gd", fzf.lsp_definitions, "goto definition")
		lsp_keymap("gr", fzf.lsp_references, "goto references")
		lsp_keymap("gI", fzf.lsp_implementations, "goto implementation")
		lsp_keymap("<leader>D", fzf.lsp_typedefs, "type definition")
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

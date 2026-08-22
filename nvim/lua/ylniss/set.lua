-- Set <space> as the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.relativenumber = true

vim.o.number = true

-- Lines kept visible above and below the cursor
vim.o.scrolloff = 10

-- Don't keep search matches highlighted
vim.o.hlsearch = false

vim.o.cursorline = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Set nushell as default shell
vim.o.shell = "nu"
vim.o.shellcmdflag = "-c"
vim.o.shellquote = ""
vim.o.shellxquote = ""
vim.o.shellpipe = "| save %s"
vim.o.shellredir = "| save %s"

-- Don't add trailing newline to files missing one
vim.o.fixeol = false

-- Sync clipboard between OS and Neovim
vim.o.clipboard = "unnamedplus"

vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = "yes"

-- Faster CursorHold and which-key popup
vim.o.updatetime = 100
vim.o.timeoutlen = 300

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank()
	end,
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
})

local function set_title()
	local filename = vim.fn.expand("%:t")
	local title_suffix = filename ~= "" and "|" .. filename or ""
	vim.o.titlestring = "nvim in " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. title_suffix
end

vim.o.title = true

set_title()

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "DirChanged" }, {
	callback = set_title,
})

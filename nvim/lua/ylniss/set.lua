vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.relativenumber = true

vim.o.number = true

-- Lines kept visible above and below the cursor
vim.o.scrolloff = 10

-- Don't keep search matches highlighted
vim.o.hlsearch = false

vim.o.cursorline = true

vim.o.mouse = "a"

vim.o.shell = "nu"
vim.o.shellcmdflag = "-c"
vim.o.shellquote = ""
vim.o.shellxquote = ""
vim.o.shellpipe = "| save %s"
vim.o.shellredir = "| save %s"

-- Don't add trailing newline to files missing one
vim.o.fixeol = false

-- Write LF, not CRLF, in new files
vim.o.fileformats = "unix,dos"

-- Sync clipboard between OS and Neovim
vim.o.clipboard = "unnamedplus"

vim.o.breakindent = true

-- Keep undo history after Neovim closes
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = "yes"

-- Faster CursorHold and a shorter wait for multi-key mappings
vim.o.updatetime = 100
vim.o.timeoutlen = 300

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank()
	end,
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
})

vim.o.title = true
vim.o.titlestring = "nvim in %{fnamemodify(getcwd(), ':t')}%(|%{expand('%:t')}%)"

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

vim.o.relativenumber = true

vim.o.number = true

vim.o.scrolloff = 10

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

vim.o.clipboard = "unnamedplus"

-- editorconfig maps max_line_length to textwidth, which hard-wraps lines while typing
require("editorconfig").properties.max_line_length = nil

vim.o.breakindent = true

vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = "yes"

-- Faster CursorHold and a shorter wait for multi-key mappings
vim.o.updatetime = 100
vim.o.timeoutlen = 300

vim.o.title = true
vim.o.titlestring = "nvim in %{fnamemodify(getcwd(), ':t')}%(|%{expand('%:t')}%)"

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank()
	end,
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
})

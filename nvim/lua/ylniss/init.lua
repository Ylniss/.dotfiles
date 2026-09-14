require("ylniss.set")

-- Bootstrap lazy.nvim plugin manager
local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazy_path) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazy_path,
	})
end
vim.opt.rtp:prepend(lazy_path)
require("lazy").setup({ import = "ylniss.plugins" })

require("ylniss.remap")
require("ylniss.indent")
require("ylniss.notes-autosync")
require("ylniss.lsp-highlight")

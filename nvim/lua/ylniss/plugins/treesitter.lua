-- ========================================================
-- Treesitter
-- Syntax highlighting and indentation
-- ========================================================
local parsers = {
	"json",
	"dockerfile",
	"terraform",
	"vimdoc",
	"vim",
	"lua",
	"bash",
	"nu",
	"sql",
	"markdown",
	"toml",
	"markdown_inline",
	"gitignore",
	"c_sharp",
	"nix",
}

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")
		ts.install(parsers)

		local function start_treesitter(buf)
			if pcall(vim.treesitter.start, buf) then
				vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end
		end

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				start_treesitter(args.buf)
			end,
		})
	end,
}

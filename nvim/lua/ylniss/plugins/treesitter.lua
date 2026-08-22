-- ========================================================
-- Treesitter
-- Syntax highlighting and code parsing
-- ========================================================
local wanted_parsers = {
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
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		event = "VeryLazy",
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			ts.setup()

			local installed = ts.get_installed("parsers")
			local missing = vim.iter(wanted_parsers)
				:filter(function(p)
					return not vim.tbl_contains(installed, p)
				end)
				:totable()
			if #missing > 0 then
				ts.install(missing)
			end

			vim.treesitter.language.register("c_sharp", { "csharp", "cs" })
			vim.treesitter.language.register("json", "jsonc")

			local function attach(buf)
				local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
				if lang and pcall(vim.treesitter.start, buf, lang) then
					vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					attach(args.buf)
				end,
			})

			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
					attach(buf)
				end
			end
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
}

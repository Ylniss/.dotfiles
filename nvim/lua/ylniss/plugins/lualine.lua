-- ========================================================
-- Lualine
-- Statusline themed by the active colorscheme
-- ========================================================
return {
	"nvim-lualine/lualine.nvim",
	priority = 999,
	opts = function()
		local theme = require("lualine.themes.auto")
		theme.normal.c.bg = "none"
		return {
			options = { theme = theme },
			sections = {
				lualine_b = {
					"branch",
					-- Built-in diff runs `git diff`, which leaves index.lock behind when Neovim kills it.
					{
						"diff",
						source = function()
							local summary = vim.b.minidiff_summary
							if not summary then
								return nil
							end
							return { added = summary.add, modified = summary.change, removed = summary.delete }
						end,
					},
					"diagnostics",
				},
			},
		}
	end,
}

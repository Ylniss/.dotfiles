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
		return { options = { theme = theme } }
	end,
}

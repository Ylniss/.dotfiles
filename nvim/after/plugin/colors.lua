require("kanagawa").setup({
	transparent = true,
	dimInactive = false,
	terminalColors = true,

	overrides = function(colors)
		local theme = colors.theme
		return {
			NormalFloat = { bg = "none" },
			FloatBorder = { bg = "none" },
			FloatTitle = { bg = "none" },

			-- Save an hlgroup with dark background and dimmed foreground
			-- so that you can use it where your still want darker windows.
			-- E.g.: autocmd TermOpen * setlocal winhighlight=Normal:NormalDark
			NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },

			-- Set themes for popular plugins
			LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
			MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

		}
	end,
})

vim.cmd.colorscheme("kanagawa")

-- Set transparent lualine
local lualine_theme = require("lualine.themes.auto")
lualine_theme.normal.c.bg = "none"
require("lualine").setup({ options = { theme = lualine_theme } })

-- Set transparent line numbers
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })

-- Colorize git signs
local color_red = "#ff6961"
local color_blue = "#54b4d8"
local color_green = "#77dd77"
vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = color_green, bg = "none" })
vim.api.nvim_set_hl(0, "GitSignsChange", { fg = color_blue, bg = "none" })
vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = color_red, bg = "none" })

-- Set the cursor color
local light_orange = "#FFA500"
vim.api.nvim_set_hl(0, "Cursor", { bg = light_orange })

-- Set custom highlight for cursorline
local color_purple = "#30184F"
vim.api.nvim_set_hl(0, "CursorLine", { bg = color_purple, fg = "", underline = false })

require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"jsonc",
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
	},

	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
})

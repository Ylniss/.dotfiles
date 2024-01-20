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

			TelescopeTitle = { fg = theme.ui.special, bold = true },
			TelescopePromptNormal = { bg = theme.ui.bg_p1 },
			TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
			TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
			TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
			TelescopePreviewNormal = { bg = theme.ui.bg_dim },
			TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
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

-- Setup same text highlights
require("illuminate").configure({
	under_cursor = false,
})

-- Coloize text color
require("ccc").setup({
	highlighter = {
		auto_enable = true,
		lsp = true,
	},
})

local function set_custom_highlights()
	vim.api.nvim_set_hl(0, "IlluminatedWordText", { fg = "Orange" })
	vim.api.nvim_set_hl(0, "IlluminatedWordRead", { fg = "Orange" })
	vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { fg = "Orange" })
end

set_custom_highlights()

--- auto update the highlight style on colorscheme change
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	pattern = { "*" },
	callback = set_custom_highlights,
})

require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"c_sharp",
		"javascript",
		"typescript",
		"html",
		"scss",
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

-- ========================================================
-- Kanagawa + Lualine
-- Colorscheme, statusline, and custom highlight groups
-- ========================================================
return {
	{
		"rebelot/kanagawa.nvim",
		name = "kanagawa",
		priority = 1000,
		config = function()
			require("kanagawa").setup({
				transparent = true,
				dimInactive = false,
				terminalColors = true,

				overrides = function(colors)
					local theme = colors.theme
					local p = colors.palette
					return {
						NormalFloat = { bg = "none" },
						FloatBorder = { bg = "none" },
						FloatTitle = { bg = "none" },
						NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
						LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
						MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

						["@markup.heading.1.markdown"] = { fg = p.autumnRed, bold = true },
						["@markup.heading.2.markdown"] = { fg = p.surimiOrange, bold = true },
						["@markup.heading.3.markdown"] = { fg = p.carpYellow, bold = true },
						["@markup.heading.4.markdown"] = { fg = p.autumnGreen, bold = true },
						["@markup.heading.5.markdown"] = { fg = p.crystalBlue, bold = true },
						["@markup.heading.6.markdown"] = { fg = p.oniViolet, bold = true },
					}
				end,
			})

			vim.cmd.colorscheme("kanagawa")

			-- Transparent line numbers
			vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
			vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })

			-- Git sign colors
			vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#77dd77", bg = "none" })
			vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#54b4d8", bg = "none" })
			vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#ff6961", bg = "none" })

			-- Cursor color
			vim.api.nvim_set_hl(0, "Cursor", { bg = "#FFA500" })

			-- Cursorline
			vim.api.nvim_set_hl(0, "CursorLine", { bg = "#30184F", fg = "", underline = false })
		end,
	},

	{
		"nvim-lualine/lualine.nvim",
		priority = 999,
		config = function()
			local lualine_theme = require("lualine.themes.auto")
			lualine_theme.normal.c.bg = "none"
			require("lualine").setup({ options = { theme = lualine_theme } })
		end,
	},
}

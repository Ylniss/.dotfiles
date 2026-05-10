-- ========================================================
-- tinted-nvim
-- Base16/24 colorscheme driven by tinty's current_scheme file
-- ========================================================
return {
	{
		"tinted-theming/tinted-nvim",
		priority = 1000,
		lazy = false,
		opts = {
			ui = {
				transparent = true,
			},
			selector = {
				enabled = true,
				mode = "file",
				path = "~/.local/share/tinted-theming/tinty/current_scheme",
				watch = true,
			},
			highlights = {
				overrides = function(palette)
					return {
						EndOfBuffer = { fg = palette.base00, bg = "none" },

						NormalFloat = { link = "Normal" },
						FloatBorder = { link = "Normal" },
						FloatTitle = { link = "Normal" },
						LineNr = { link = "Normal" },
						SignColumn = { link = "Normal" },

						FzfLuaNormal = { link = "Normal" },
						FzfLuaBorder = { link = "Normal" },
						FzfLuaTitle = { link = "Normal" },
						FzfLuaPreviewNormal = { link = "Normal" },
						FzfLuaPreviewBorder = { link = "Normal" },
						FzfLuaPreviewTitle = { link = "Normal" },
						FzfLuaHelpNormal = { link = "Normal" },
						FzfLuaHelpBorder = { link = "Normal" },

						WhichKeyFloat = { link = "Normal" },
						WhichKeyBorder = { link = "Normal" },
						WhichKeyTitle = { link = "Normal" },

						IblIndent = { fg = palette.base02 },
						IblWhitespace = { fg = palette.base02 },
						IblScope = { fg = palette.base04 },

						GitSignsAdd = { fg = palette.base0B, bg = "none" },
						GitSignsChange = { fg = palette.base0D, bg = "none" },
						GitSignsDelete = { fg = palette.base08, bg = "none" },

						CursorLine = { bg = palette.base02, underline = false },

						LspReferenceText = { bg = palette.base03 },
						LspReferenceRead = { bg = palette.base03 },
						LspReferenceWrite = { bg = palette.base03 },

						["@property"] = { fg = palette.base0D },
						["@variable.member"] = { fg = palette.base0D },
						["@variable.parameter"] = { fg = palette.base09 },
						["@punctuation.bracket"] = { fg = palette.base04 },
						["@punctuation.delimiter"] = { fg = palette.base04 },

						["@markup.heading.1.markdown"] = { fg = palette.base08, bold = true },
						["@markup.heading.2.markdown"] = { fg = palette.base09, bold = true },
						["@markup.heading.3.markdown"] = { fg = palette.base0A, bold = true },
						["@markup.heading.4.markdown"] = { fg = palette.base0B, bold = true },
						["@markup.heading.5.markdown"] = { fg = palette.base0D, bold = true },
						["@markup.heading.6.markdown"] = { fg = palette.base0E, bold = true },
					}
				end,
			},
		},
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

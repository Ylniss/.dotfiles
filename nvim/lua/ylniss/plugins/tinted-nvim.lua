-- ========================================================
-- tinted-nvim
-- Base16/24 colorscheme driven by tinty's current_scheme file
-- ========================================================
return {
	"tinted-theming/tinted-nvim",
	priority = 1000,
	lazy = false,
	opts = {
		ui = {
			transparent = true,
		},
		selector = { enabled = true },
		highlights = {
			overrides = function(palette)
				return {
					EndOfBuffer = { fg = palette.base00, bg = "none" },

					FloatBorder = { link = "Normal" },
					FloatTitle = { link = "Normal" },
					LineNr = { link = "Normal" },
					SignColumn = { link = "Normal" },

					IblIndent = { fg = palette.base02 },
					IblWhitespace = { fg = palette.base02 },
					IblScope = { fg = palette.base04 },

					MiniDiffSignAdd = { fg = palette.base0B, bg = "none" },
					MiniDiffSignChange = { fg = palette.base0D, bg = "none" },
					MiniDiffSignDelete = { fg = palette.base08, bg = "none" },

					-- Overlay: old text red, new text green; changed words get a stronger tint.
					-- `darken` amount is the share of theme background mixed into the color.
					MiniDiffOverDelete = { fg = palette.base08, bg = { darken = palette.base08, amount = 0.75 } },
					MiniDiffOverContext = { link = "MiniDiffOverDelete" },
					MiniDiffOverChange = { fg = palette.base05, bg = { darken = palette.base08, amount = 0.45 } },
					MiniDiffOverAdd = { bg = { darken = palette.base0B, amount = 0.75 } },
					MiniDiffOverContextBuf = { link = "MiniDiffOverAdd" },
					MiniDiffOverChangeBuf = { bg = { darken = palette.base0B, amount = 0.45 } },

					CursorLine = { bg = palette.base02, underline = false },

					LspReferenceText = { bg = palette.base03 },

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
}

-- ========================================================
-- tinted-nvim
-- Base16/24 colorscheme driven by tinty's current_scheme file
-- ========================================================

local function read_palette()
	local home = os.getenv("HOME") or ""
	local f = io.open(home .. "/.local/share/tinted-theming/tinty/current_scheme", "r")
	if not f then return nil end
	local scheme_slug = (f:read("*line") or ""):gsub("%s+$", "")
	f:close()
	local system, scheme_name = scheme_slug:match("^(base%d+)%-(.+)$")
	if not system then return nil end
	local yaml_f = io.open(string.format(
		"%s/.local/share/tinted-theming/tinty/repos/schemes/%s/%s.yaml",
		home, system, scheme_name), "r")
	if not yaml_f then return nil end
	local palette = {}
	local in_palette = false
	for line in yaml_f:lines() do
		if line:match("^palette:") then
			in_palette = true
		elseif in_palette then
			if line:match("^%S") then break end
			local key, value = line:match("^%s+(base%w+)%s*:%s*[\"']?(#%x+)[\"']?")
			if key and value then palette[key] = value end
		end
	end
	yaml_f:close()
	return palette
end

local function apply_overrides()
	local palette = read_palette()
	if not palette then return end
	local hl = vim.api.nvim_set_hl

	-- Pane transparency (preserve fg)
	hl(0, "Normal", { fg = palette.base05, bg = "none" })
	hl(0, "NormalNC", { fg = palette.base05, bg = "none" })
	hl(0, "EndOfBuffer", { fg = palette.base00, bg = "none" })

	-- Floating window / gutter
	hl(0, "NormalFloat", { bg = "none" })
	hl(0, "FloatBorder", { bg = "none" })
	hl(0, "FloatTitle", { bg = "none" })
	hl(0, "LineNr", { bg = "none" })
	hl(0, "SignColumn", { bg = "none" })

	-- fzf-lua
	hl(0, "FzfLuaNormal", { bg = "none" })
	hl(0, "FzfLuaBorder", { bg = "none" })
	hl(0, "FzfLuaTitle", { bg = "none" })
	hl(0, "FzfLuaPreviewNormal", { bg = "none" })
	hl(0, "FzfLuaPreviewBorder", { bg = "none" })
	hl(0, "FzfLuaPreviewTitle", { bg = "none" })
	hl(0, "FzfLuaHelpNormal", { bg = "none" })
	hl(0, "FzfLuaHelpBorder", { bg = "none" })

	-- which-key
	hl(0, "WhichKeyFloat", { bg = "none" })
	hl(0, "WhichKeyBorder", { bg = "none" })
	hl(0, "WhichKeyTitle", { bg = "none" })

	-- indent-blankline (groups must exist or ibl.setup errors)
	hl(0, "IblIndent", { fg = palette.base02 })
	hl(0, "IblWhitespace", { fg = palette.base02 })
	hl(0, "IblScope", { fg = palette.base04 })

	-- Git signs
	hl(0, "GitSignsAdd", { fg = palette.base0B, bg = "none" })
	hl(0, "GitSignsChange", { fg = palette.base0D, bg = "none" })
	hl(0, "GitSignsDelete", { fg = palette.base08, bg = "none" })

	-- Cursorline
	hl(0, "CursorLine", { bg = palette.base02, underline = false })

	-- Treesitter captures tinted-nvim leaves at Normal (keys/brackets/params)
	hl(0, "@property", { fg = palette.base0D })
	hl(0, "@variable.member", { fg = palette.base0D })
	hl(0, "@variable.parameter", { fg = palette.base09 })
	hl(0, "@punctuation.bracket", { fg = palette.base04 })
	hl(0, "@punctuation.delimiter", { fg = palette.base04 })

	-- Markdown heading rainbow
	hl(0, "@markup.heading.1.markdown", { fg = palette.base08, bold = true })
	hl(0, "@markup.heading.2.markdown", { fg = palette.base09, bold = true })
	hl(0, "@markup.heading.3.markdown", { fg = palette.base0A, bold = true })
	hl(0, "@markup.heading.4.markdown", { fg = palette.base0B, bold = true })
	hl(0, "@markup.heading.5.markdown", { fg = palette.base0D, bold = true })
	hl(0, "@markup.heading.6.markdown", { fg = palette.base0E, bold = true })
end

return {
	{
		"tinted-theming/tinted-nvim",
		priority = 1000,
		lazy = false,
		opts = {
			selector = {
				enabled = true,
				mode = "file",
				path = "~/.local/share/tinted-theming/tinty/current_scheme",
				watch = true,
			},
		},
		init = function()
			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "*",
				callback = apply_overrides,
			})
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

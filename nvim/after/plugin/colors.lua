require("kanagawa").setup({
    transparent = true,         -- do not set background color
    dimInactive = false,         -- dim inactive window `:h hl-NormalNC`
    terminalColors = false,

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
local lualine_theme = require('lualine.themes.auto')
lualine_theme.normal.c.bg = 'none'
require('lualine').setup { options = { theme = lualine_theme } }


-- Set transparent line numbers
local color_red = '#ff6961'
local color_blue = '#54b4d8'
local color_green = '#77dd77'

vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = color_green, bg = "none" })
vim.api.nvim_set_hl(0, "GitSignsChange", { fg = color_blue, bg = "none" })
vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = color_red, bg = "none" })

require('illuminate').configure({
    under_cursor = false,
})

local function set_custom_highlights()
  vim.api.nvim_set_hl(0, "IlluminatedWordText", { fg = "Orange", bg = "DarkBlue" })
  vim.api.nvim_set_hl(0, "IlluminatedWordRead", { fg = "Orange", bg = "DarkBlue" })
  vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { fg = "Orange", bg = "DarkBlue" })

  -- vim.api.nvim_set_hl(0, "IlluminatedWordText", { bg = "LightGrey" })
  -- vim.api.nvim_set_hl(0, "IlluminatedWordRead", { bg = "LightGrey" })
  -- vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bg = "LightGrey" })
  --
  -- vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
  -- vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
  -- vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
end

set_custom_highlights()

--- auto update the highlight style on colorscheme change
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  pattern = { "*" },
  callback = set_custom_highlights
})

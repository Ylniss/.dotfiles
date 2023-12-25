local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

config.color_scheme = 'AdventureTime 40m'
config.font = wezterm.font 'JetBrainsMono NF'

config.window_background_opacity = 0.8

config.window_frame = {
  -- The font used in the tab bar.
  font = wezterm.font { family = 'Roboto', weight = 'Bold' },

  -- The size of the font in the tab bar.
  font_size = 11.0,

  active_titlebar_bg = '#333333',
  inactive_titlebar_bg = '#333333',
}

config.default_prog = { 'C:/Program Files/PowerShell/7/pwsh.exe' }

return config

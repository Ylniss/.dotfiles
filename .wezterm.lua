local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

local is_windows = wezterm.target_triple == 'x86_64-pc-windows-msvc'

if is_windows then
  config.default_prog = { 'C:/Program Files/PowerShell/7/pwsh.exe' }
end

-- =========== APPEARANCE ===========

config.color_scheme = 'Banana Blueberry'

config.font = wezterm.font 'JetBrainsMono NF'
config.font_size = 10.5


-- ============= WINDOW =============

config.window_background_opacity = 0.85

config.window_frame = {
  -- The font used in the tab bar.
  font = wezterm.font { family = 'Roboto', weight = 'Bold' },

  -- The size of the font in the tab bar.
  font_size = 11.0,

  active_titlebar_bg = '#333333',
  inactive_titlebar_bg = '#333333',
}

local function get_current_working_dir(tab)
  local current_dir = tab.active_pane.current_working_dir
  local home_dir = string.format("file://%s", os.getenv("HOME"))

  return current_dir == home_dir and "." or string.gsub(current_dir, "(.*[/\\])(.*)", "%2")
end

-- Set tab title as current working dir
wezterm.on("format-tab-title", function(tab)
  local title = string.format(" %s  %s ~ %s  ", "❯", get_current_working_dir(tab))

  return {
    { Text = title },
  }
end)


-- ========== KEY BINDINGS ==========

config.keys = {
  -- Ctrl + number to focus on <number> tab
  { key = "1", mods = "CTRL", action = wezterm.action { ActivateTab = 0 }},
  { key = "2", mods = "CTRL", action = wezterm.action { ActivateTab = 1 }},
  { key = "3", mods = "CTRL", action = wezterm.action { ActivateTab = 2 }},
  { key = "4", mods = "CTRL", action = wezterm.action { ActivateTab = 3 }},
  { key = "5", mods = "CTRL", action = wezterm.action { ActivateTab = 4 }},
  { key = "6", mods = "CTRL", action = wezterm.action { ActivateTab = 5 }},
  { key = "7", mods = "CTRL", action = wezterm.action { ActivateTab = 6 }},
  { key = "8", mods = "CTRL", action = wezterm.action { ActivateTab = 7 }},
  { key = "9", mods = "CTRL", action = wezterm.action { ActivateTab = -1 }},

  -- Ctrl + T to open a new tab
  { key = "t", mods = "CTRL", action = wezterm.action { SpawnTab = "CurrentPaneDomain" }},

  -- Ctrl + Shift + v to split vertically
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action { SplitVertical = { domain = "CurrentPaneDomain" }}},

  -- Ctrl + Shift + h to split vertically
  { key = "h", mods = "CTRL|SHIFT", action = wezterm.action { SplitHorizontal = { domain = "CurrentPaneDomain" }}},

  -- Ctrl + Alt + Arrow to resize in arrow direction
  { key = "UpArrow", mods = "CTRL|ALT", action = wezterm.action { AdjustPaneSize = { "Up", 1 }}},
  { key = "DownArrow", mods = "CTRL|ALT", action = wezterm.action { AdjustPaneSize = { "Down", 1 }}},
  { key = "LeftArrow", mods = "CTRL|ALT", action = wezterm.action { AdjustPaneSize = { "Left", 1 }}},
  { key = "RightArrow", mods = "CTRL|ALT", action = wezterm.action { AdjustPaneSize = { "Right", 1 }}},

  { key = 'F11', action = wezterm.action.ToggleFullScreen },

  -- Alt + l to show launcher opetions
  { key = 'l', mods = 'ALT', action = wezterm.action.ShowLauncher },
}

return config

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

config.window_background_opacity = 0.85

local titlebar_color = '#0B0022'
config.show_new_tab_button_in_tab_bar = false
config.switch_to_last_active_tab_when_closing_tab = true

config.window_frame = {
  -- The font used in the tab bar.
  font = wezterm.font { family = 'JetBrainsMono NF' },

  -- The size of the font in the tab bar.
  font_size = 12.0,

  active_titlebar_bg = titlebar_color,
  inactive_titlebar_bg = titlebar_color,
}

local function tab_title(tab)
  local title = tab.tab_title

  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab.active_pane.title
end

wezterm.on(
  'format-tab-title',
  function(tab, tabs, panes, config, hover, max_width)
    local edge_background = titlebar_color
    local background = '#1b1032'
    local foreground = '#808080'
    local edge_foreground = background

    if tab.is_active then
      background = '#2B2042'
      foreground = '#C0C0C0'
      edge_foreground = background
    elseif hover then
      background = '#3b3052'
      foreground = '#909090'
    end

    local title = tab_title(tab)

    return {
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = wezterm.nerdfonts.pl_right_hard_divider },
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = " " .. title .. " " },
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = wezterm.nerdfonts.pl_left_hard_divider },
    }
  end
)


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

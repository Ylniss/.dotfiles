local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ============ BEHAVIOR ============

local is_windows = wezterm.target_triple:find("windows") ~= nil

config.default_prog = { "nu" }

config.window_close_confirmation = "NeverPrompt"
config.canonicalize_pasted_newlines = "LineFeed"

config.show_new_tab_button_in_tab_bar = false
config.switch_to_last_active_tab_when_closing_tab = true

-- =========== APPEARANCE ===========

local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""

local scheme

if is_windows then
	config.color_scheme = "Ef-Cherie"
	scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
else
	scheme = require("tinty").load_tinty_scheme()
	if scheme then
		config.color_schemes = { tinty = scheme }
		config.color_scheme = "tinty"
		wezterm.add_to_config_reload_watch_list(home .. "/.local/share/tinted-theming/tinty/current_scheme")
	else
		config.color_scheme = "Ef-Cherie"
		scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
	end
end

config.initial_cols = 135
config.initial_rows = 34

-- Windows registers the Nerd Font under a different family name than Linux
local nerd_font = is_windows and "JetBrainsMono NF" or "JetBrainsMonoNerdFont"

config.font = wezterm.font(nerd_font)
config.font_size = 11
config.line_height = 1

-- Windows: RESIZE keeps the resize border (NONE strips it). Linux/Wayland: NONE hides the CSD titlebar.
config.window_decorations = is_windows and "RESIZE" or "NONE"
config.window_background_opacity = 0.95
if is_windows then
	config.win32_system_backdrop = "Acrylic"
end

-- titlebar bg only honors opacity if given an explicit alpha
local function with_alpha(hex, alpha)
	local r = tonumber(hex:sub(2, 3), 16)
	local g = tonumber(hex:sub(4, 5), 16)
	local b = tonumber(hex:sub(6, 7), 16)
	return string.format("rgba(%d,%d,%d,%.3f)", r, g, b, alpha)
end

config.window_frame = {
	font = wezterm.font({ family = nerd_font }),
	font_size = 10,
	active_titlebar_bg = with_alpha(scheme.background, config.window_background_opacity),
	inactive_titlebar_bg = with_alpha(scheme.background, config.window_background_opacity),
}

require("tabs").setup(scheme, is_windows)

-- ========== KEY BINDINGS ==========

local keys = require("keys")
config.keys = keys.bindings
config.key_tables = { copy_mode = keys.copy_mode() }

return config

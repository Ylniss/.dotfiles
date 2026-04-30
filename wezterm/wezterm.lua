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

local function read_tinty_scheme_slug()
	local f = io.open(home .. "/.local/share/tinted-theming/tinty/current_scheme", "r")
	if not f then
		return nil
	end
	local slug = (f:read("*l") or ""):gsub("%s+$", "")
	f:close()
	if slug == "" then
		return nil
	end
	return slug
end

if is_windows then
	config.color_scheme = "Ef-Cherie"
	scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
else
	-- Register inline so reloads resolve the slug even if wezterm started
	-- before the colors/ symlink existed.
	local slug = read_tinty_scheme_slug()
	if slug then
		local loaded = wezterm.color.load_scheme(home .. "/.config/wezterm/colors/" .. slug .. ".toml")
		if loaded then
			config.color_schemes = { [slug] = loaded }
			config.color_scheme = slug
			scheme = loaded
		end
	end
	if not scheme then
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
config.window_background_opacity = 0.75
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

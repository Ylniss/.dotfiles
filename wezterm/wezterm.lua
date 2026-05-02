local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ============ BEHAVIOR ============

local is_windows = wezterm.target_triple:find("windows") ~= nil

config.default_prog = { "nu" }

config.window_close_confirmation = "NeverPrompt"
config.canonicalize_pasted_newlines = "LineFeed"

-- Wayland: re-copy clipboard on focus change so paste works between wezterm windows.
if os.getenv("WAYLAND_DISPLAY") then
	wezterm.on("window-focus-changed", function()
		wezterm.run_child_process({ "sh", "-c", "wl-paste -n | wl-copy" })
	end)
end

config.show_new_tab_button_in_tab_bar = false
config.switch_to_last_active_tab_when_closing_tab = true
config.use_fancy_tab_bar = false
config.tab_max_width = 48

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
			-- keep 256-color index 16 as default black (LS_COLORS expects it)
			if loaded.indexed then
				loaded.indexed[16] = nil
			end
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
	local r, g, b = wezterm.color.parse(hex):srgba_u8()
	return string.format("rgba(%d,%d,%d,%.3f)", r, g, b, alpha)
end

config.window_frame = {
	font = wezterm.font({ family = nerd_font }),
	font_size = 10,
	active_titlebar_bg = with_alpha(scheme.background, config.window_background_opacity),
	inactive_titlebar_bg = with_alpha(scheme.background, config.window_background_opacity),
}

local outer = with_alpha(scheme.background, config.window_background_opacity)
-- indexed[19]=base03, [20]=base04 (base24 extended palette)
local active_bg = (scheme.indexed and scheme.indexed[19]) or scheme.selection_bg or "#3a3a3a"
local inactive_fg = (scheme.indexed and scheme.indexed[20]) or "#808080"

config.colors = {
	tab_bar = {
		background = outer,
		active_tab = {
			bg_color = active_bg,
			fg_color = scheme.foreground,
		},
		inactive_tab = {
			bg_color = outer,
			fg_color = inactive_fg,
		},
		inactive_tab_hover = {
			bg_color = active_bg,
			fg_color = scheme.foreground,
		},
	},
}

-- ========== KEY BINDINGS ==========

local keys = require("keys")
config.keys = keys.bindings
config.key_tables = { copy_mode = keys.copy_mode() }

return config

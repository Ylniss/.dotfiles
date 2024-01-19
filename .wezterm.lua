local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- ============ BEHAVIOR ============

local is_windows = wezterm.target_triple == "x86_64-pc-windows-msvc"

if is_windows then
	config.default_prog = { "pwsh" }
end

config.window_close_confirmation = "NeverPrompt"

config.show_new_tab_button_in_tab_bar = false
config.switch_to_last_active_tab_when_closing_tab = true

-- =========== APPEARANCE ===========

config.color_scheme = "Banana Blueberry"

config.window_decorations = "RESIZE"
config.initial_cols = 135
config.initial_rows = 34

config.font = wezterm.font("JetBrainsMono NF")
config.font_size = 10.5
config.line_height = 0.9

config.window_background_opacity = 0.85

local titlebar_color = "#0B0022"

config.window_frame = {
	-- The font used in the tab bar.
	font = wezterm.font({ family = "JetBrainsMono NF" }),

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

	local pane = tab.active_pane
	local fg_process_name = pane.foreground_process_name
	if fg_process_name then
		-- Extracts only the program name without the extension and path
		fg_process_name = fg_process_name:match("([^\\/]*)$")
		-- Optionally remove the file extension if present
		fg_process_name = fg_process_name:match("(.+)%..+") or fg_process_name
	end

	-- If a foreground process is running, use its name and the last part of the current path
	if
		fg_process_name
		and #fg_process_name > 0
		and fg_process_name ~= "nvim"
		and fg_process_name ~= "lf"
		and fg_process_name ~= "pwsh"
	then
		--Bug on Windows so commented out: https://github.com/wez/wezterm/issues/3841
		-- local cwd = pane:get_current_working_dir()
		-- if cwd then
		-- 	local path_segments = {}
		-- 	for segment in string.gmatch(cwd.path, "[^/]+") do
		-- 		table.insert(path_segments, segment)
		-- 	end
		-- 	local last_part_of_path = path_segments[#path_segments] or ""
		-- 	return fg_process_name .. " in " .. last_part_of_path
		-- else
		return fg_process_name
		-- end
	end

	-- Otherwise, use the title from the active pane in that tab
	return pane.title
end

-- local function tab_title(tab)
-- 	local title = tab.tab_title
--
-- 	-- if the tab title is explicitly set, take that
-- 	if title and #title > 0 then
-- 		return title
-- 	end
-- 	-- Otherwise, use the title from the active pane in that tab
-- 	return tab.active_pane.title
-- end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local edge_background = titlebar_color
	local background = "#1b1032"
	local foreground = "#808080"
	local edge_foreground = background

	if tab.is_active then
		background = "#2B2042"
		foreground = "#C0C0C0"
		edge_foreground = background
	elseif hover then
		background = "#3b3052"
		foreground = "#909090"
	end

	local title = tab_title(tab)

	return {
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = wezterm.nerdfonts.pl_right_hard_divider },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = " " .. tostring(tab.tab_index + 1) .. ": " .. title .. " " },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = wezterm.nerdfonts.pl_left_hard_divider },
	}
end)

-- ========== KEY BINDINGS ==========

config.keys = {
	-- Ctrl + number to focus on <number> tab
	{ key = "1", mods = "CTRL", action = wezterm.action({ ActivateTab = 0 }) },
	{ key = "2", mods = "CTRL", action = wezterm.action({ ActivateTab = 1 }) },
	{ key = "3", mods = "CTRL", action = wezterm.action({ ActivateTab = 2 }) },
	{ key = "4", mods = "CTRL", action = wezterm.action({ ActivateTab = 3 }) },
	{ key = "5", mods = "CTRL", action = wezterm.action({ ActivateTab = 4 }) },
	{ key = "6", mods = "CTRL", action = wezterm.action({ ActivateTab = 5 }) },
	{ key = "7", mods = "CTRL", action = wezterm.action({ ActivateTab = 6 }) },
	{ key = "8", mods = "CTRL", action = wezterm.action({ ActivateTab = 7 }) },
	{ key = "9", mods = "CTRL", action = wezterm.action({ ActivateTab = -1 }) },

	-- Ctrl + T to open a new tab
	{ key = "t", mods = "CTRL", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },

	-- Ctrl + Shift + T to close current tab
	{
		key = "t",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }), pane)
			window:perform_action(wezterm.action({ ActivatePaneDirection = "Down" }), pane)
			window:perform_action(wezterm.action({ AdjustPaneSize = { "Down", 20 } }), pane)
		end),
	},

	-- Ctrl + Shift + Q to close current tab
	{ key = "q", mods = "CTRL|SHIFT", action = wezterm.action({ CloseCurrentTab = { confirm = false } }) },

	-- Ctrl + Shift + W to close current pane
	{ key = "w", mods = "CTRL|SHIFT", action = wezterm.action({ CloseCurrentPane = { confirm = false } }) },

	-- Ctrl + Shift + v to split vertically
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }) },

	-- Ctrl + Shift + h to split vertically
	{ key = "h", mods = "CTRL|SHIFT", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },

	-- Ctrl + Alt + Arrow to resize in arrow direction
	{ key = "UpArrow", mods = "CTRL|ALT", action = wezterm.action({ AdjustPaneSize = { "Up", 1 } }) },
	{ key = "DownArrow", mods = "CTRL|ALT", action = wezterm.action({ AdjustPaneSize = { "Down", 1 } }) },
	{ key = "LeftArrow", mods = "CTRL|ALT", action = wezterm.action({ AdjustPaneSize = { "Left", 1 } }) },
	{ key = "RightArrow", mods = "CTRL|ALT", action = wezterm.action({ AdjustPaneSize = { "Right", 1 } }) },

	-- Ctrl + e/y to scroll up or down
	{ key = "e", mods = "CTRL", action = wezterm.action.ScrollByLine(-1) },
	{ key = "y", mods = "CTRL", action = wezterm.action.ScrollByLine(1) },

	{ key = "F11", action = wezterm.action.ToggleFullScreen },

	-- Alt + l to show launcher opetions
	{ key = "l", mods = "ALT", action = wezterm.action.ShowLauncher },
}

return config

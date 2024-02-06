local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- ============ BEHAVIOR ============

local is_windows = wezterm.target_triple == "x86_64-pc-windows-msvc"

if is_windows then
	config.default_prog = { "nu" }
end

config.window_close_confirmation = "NeverPrompt"

config.show_new_tab_button_in_tab_bar = false
config.switch_to_last_active_tab_when_closing_tab = true

-- Setup compatibility with nvim splits keybindings
local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
				}, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

-- =========== APPEARANCE ===========

config.color_scheme = "Banana Blueberry"

config.colors = {
	selection_fg = "black",
	selection_bg = "#fe965b",
}

config.initial_cols = 135
config.initial_rows = 34

config.font = wezterm.font("JetBrainsMono NF")
config.font_size = 10.5
config.line_height = 0.9

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.88
if is_windows then
	config.win32_system_backdrop = "Acrylic"
end

config.window_background_gradient = {
	colors = {
		"#0b0014",
		"#17003e",
		"#0b0014",
	},
	blend = "Hsv",
	orientation = "Vertical",
}

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
		fg_process_name = fg_process_name:match("(.+)%..+") or fg_process_name
	end

	-- If a foreground process is running, use its name and the last part of the current path
	if fg_process_name and #fg_process_name > 0 and (fg_process_name == "lazydocker" or fg_process_name == "nu") then
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

local act = wezterm.action

config.keys = {
	-- Ctrl + number to focus on <number> tab
	{ key = "1", mods = "CTRL", action = act({ ActivateTab = 0 }) },
	{ key = "2", mods = "CTRL", action = act({ ActivateTab = 1 }) },
	{ key = "3", mods = "CTRL", action = act({ ActivateTab = 2 }) },
	{ key = "4", mods = "CTRL", action = act({ ActivateTab = 3 }) },
	{ key = "5", mods = "CTRL", action = act({ ActivateTab = 4 }) },
	{ key = "6", mods = "CTRL", action = act({ ActivateTab = 5 }) },
	{ key = "7", mods = "CTRL", action = act({ ActivateTab = 6 }) },
	{ key = "8", mods = "CTRL", action = act({ ActivateTab = 7 }) },
	{ key = "9", mods = "CTRL", action = act({ ActivateTab = 8 }) },
	{ key = "0", mods = "CTRL", action = act({ ActivateTab = -1 }) },

	-- move between split panes
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	-- resize panes
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),

	-- Ctrl + T to open a new tab
	{ key = "t", mods = "CTRL", action = act({ SpawnTab = "CurrentPaneDomain" }) },

	-- Ctrl + Shift + T to create small pane on the bottom (terminal)
	{
		key = "t",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(act({ SplitVertical = { domain = "CurrentPaneDomain" } }), pane)
			window:perform_action(act({ ActivatePaneDirection = "Down" }), pane)
			window:perform_action(act({ AdjustPaneSize = { "Down", 20 } }), pane)
		end),
	},

	-- Ctrl + Shift + Q to close current tab
	{ key = "q", mods = "CTRL|SHIFT", action = act({ CloseCurrentTab = { confirm = false } }) },

	-- Ctrl + Shift + W to close current pane
	{ key = "w", mods = "CTRL|SHIFT", action = act({ CloseCurrentPane = { confirm = false } }) },

	-- Ctrl + Shift + V to split vertically
	{ key = "v", mods = "CTRL|SHIFT", action = act({ SplitHorizontal = { domain = "CurrentPaneDomain" } }) },

	-- Ctrl + Shift + H to split vertically
	{ key = "h", mods = "CTRL|SHIFT", action = act({ SplitVertical = { domain = "CurrentPaneDomain" } }) },

	-- Ctrl + Alt + Arrow to resize in arrow direction
	{ key = "UpArrow", mods = "CTRL|ALT", action = act({ AdjustPaneSize = { "Up", 1 } }) },
	{ key = "DownArrow", mods = "CTRL|ALT", action = act({ AdjustPaneSize = { "Down", 1 } }) },
	{ key = "LeftArrow", mods = "CTRL|ALT", action = act({ AdjustPaneSize = { "Left", 1 } }) },
	{ key = "RightArrow", mods = "CTRL|ALT", action = act({ AdjustPaneSize = { "Right", 1 } }) },

	-- Ctrl + e/y to scroll up or down
	{ key = "e", mods = "CTRL", action = act.ScrollByLine(-1) },
	{ key = "y", mods = "CTRL", action = act.ScrollByLine(1) },

	{ key = "F11", action = act.ToggleFullScreen },

	-- Alt + Shift + L to show launcher opetions
	{ key = "l", mods = "SHIFT|ALT", action = act.ShowLauncher },

	-- Ctrl + V to paste
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
}

local copy_mode = nil
if wezterm.gui then
	copy_mode = wezterm.gui.default_key_tables().copy_mode
	local keybindings = {
		{ key = "l", mods = "SHIFT", action = wezterm.action.CopyMode("MoveForwardWord") },
		{ key = "h", mods = "SHIFT", action = wezterm.action.CopyMode("MoveBackwardWord") },
	}

	for _, keybinding in ipairs(keybindings) do
		table.insert(copy_mode, keybinding)
	end
end

config.key_tables = {
	copy_mode = copy_mode,
}

return config

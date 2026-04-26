local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ============ BEHAVIOR ============

local is_windows = wezterm.target_triple:find("windows") ~= nil

config.default_prog = { "nu" }

config.window_close_confirmation = "NeverPrompt"
config.canonicalize_pasted_newlines = "LineFeed"

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
				win:perform_action(
					act.SendKey({ key = key, mods = resize_or_move == "resize" and "META" or "CTRL" }),
					pane
				)
				return
			end
			if resize_or_move == "resize" then
				win:perform_action(act.AdjustPaneSize({ direction_keys[key], 3 }), pane)
			else
				win:perform_action(act.ActivatePaneDirection(direction_keys[key]), pane)
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

config.font = wezterm.font("JetBrains Mono")
config.font_size = 11
config.line_height = 1

config.window_decorations = "NONE"
config.window_background_opacity = 0.85
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
	font = wezterm.font({ family = "JetBrainsMono NF" }),
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
		if not is_windows then
			local cwd = pane:get_current_working_dir()
			if cwd then
				local path_segments = {}
				for segment in string.gmatch(cwd.path, "[^/]+") do
					table.insert(path_segments, segment)
				end
				local last_part_of_path = path_segments[#path_segments] or ""
				return fg_process_name .. " in " .. last_part_of_path
			end
		end
		return fg_process_name
	end

	-- Otherwise, use the title from the active pane, stripping .exe suffix on Windows
	local t = pane.title
	return t:gsub("%.exe", "")
end

wezterm.on("format-tab-title", function(tab, _, _, _, hover, _)
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
		edge_foreground = background
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
	{ key = "1", mods = "CTRL", action = act.ActivateTab(0) },
	{ key = "2", mods = "CTRL", action = act.ActivateTab(1) },
	{ key = "3", mods = "CTRL", action = act.ActivateTab(2) },
	{ key = "4", mods = "CTRL", action = act.ActivateTab(3) },
	{ key = "5", mods = "CTRL", action = act.ActivateTab(4) },
	{ key = "6", mods = "CTRL", action = act.ActivateTab(5) },
	{ key = "7", mods = "CTRL", action = act.ActivateTab(6) },
	{ key = "8", mods = "CTRL", action = act.ActivateTab(7) },
	{ key = "9", mods = "CTRL", action = act.ActivateTab(8) },
	{ key = "0", mods = "CTRL", action = act.ActivateTab(-1) },

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
	{ key = "t", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },

	-- Ctrl + Shift + T to create small pane on the bottom (terminal)
	{
		key = "t",
		mods = "CTRL|SHIFT",
		action = act.Multiple({
			act.SplitVertical({ domain = "CurrentPaneDomain" }),
			act.ActivatePaneDirection("Down"),
			act.AdjustPaneSize({ "Down", 20 }),
		}),
	},

	-- Ctrl + Shift + Q to close current pane
	{ key = "q", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },

	-- Ctrl + Shift + W to close current tab
	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },

	-- Ctrl + Shift + V to split horizontally (side by side)
	{ key = "v", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

	-- Ctrl + Shift + H to split vertically (stacked)
	{ key = "h", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Ctrl + e/y to scroll up or down
	{ key = "e", mods = "CTRL", action = act.ScrollByLine(-1) },
	{ key = "y", mods = "CTRL", action = act.ScrollByLine(1) },

	{ key = "F11", action = act.ToggleFullScreen },

	-- Alt + Shift + L to show launcher options
	{ key = "l", mods = "SHIFT|ALT", action = act.ShowLauncher },

	-- Ctrl + V to paste
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },

	-- Shift + Enter to insert newline (for Claude Code)
	{ key = "Enter", mods = "SHIFT", action = act.SendString("\n") },

	-- Ctrl + C: copy if text is selected, otherwise send interrupt
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local sel = window:get_selection_text_for_pane(pane)
			if sel ~= "" then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},
}

local copy_mode = nil
if wezterm.gui then
	copy_mode = wezterm.gui.default_key_tables().copy_mode
	local keybindings = {
		{ key = "l", mods = "SHIFT", action = act.CopyMode("MoveForwardWord") },
		{ key = "h", mods = "SHIFT", action = act.CopyMode("MoveBackwardWord") },
	}

	for _, keybinding in ipairs(keybindings) do
		table.insert(copy_mode, keybinding)
	end
end

config.key_tables = {
	copy_mode = copy_mode,
}

return config

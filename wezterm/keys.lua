-- ========================================================
-- keys
-- Wezterm key bindings + copy-mode key table
-- ========================================================

local wezterm = require("wezterm")
local act = wezterm.action
local split_nav = require("nvim-splits").split_nav

local M = {}

M.bindings = {
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

function M.copy_mode()
	if not wezterm.gui then
		return nil
	end
	local copy_mode = wezterm.gui.default_key_tables().copy_mode
	local extras = {
		{ key = "l", mods = "SHIFT", action = act.CopyMode("MoveForwardWord") },
		{ key = "h", mods = "SHIFT", action = act.CopyMode("MoveBackwardWord") },
	}
	for _, kb in ipairs(extras) do
		table.insert(copy_mode, kb)
	end
	return copy_mode
end

return M

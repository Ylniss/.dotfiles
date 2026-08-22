-- ========================================================
-- keys
-- Wezterm key bindings + copy-mode key table
-- ========================================================

local wezterm = require("wezterm")
local act = wezterm.action
local split_nav = require("nvim-splits").split_nav

local M = {}

M.bindings = {
	{ key = "t", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },

	-- Small terminal pane docked at the bottom
	{
		key = "t",
		mods = "CTRL|SHIFT",
		action = act.Multiple({
			act.SplitVertical({ domain = "CurrentPaneDomain" }),
			act.ActivatePaneDirection("Down"),
			act.AdjustPaneSize({ "Down", 20 }),
		}),
	},

	{ key = "q", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },

	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },

	-- split side by side
	{ key = "v", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

	-- split stacked
	{ key = "h", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	{ key = "e", mods = "CTRL", action = act.ScrollByLine(-1) },
	{ key = "y", mods = "CTRL", action = act.ScrollByLine(1) },

	{ key = "F11", action = act.ToggleFullScreen },

	{ key = "l", mods = "SHIFT|ALT", action = act.ShowLauncher },

	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },

	-- for Claude Code
	{ key = "Enter", mods = "SHIFT", action = act.SendString("\n") },

	-- copy if text is selected, otherwise send interrupt
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local selected_text = window:get_selection_text_for_pane(pane)
			if selected_text ~= "" then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},
}

for _, key in ipairs({ "h", "j", "k", "l" }) do
	table.insert(M.bindings, split_nav("move", key))
	table.insert(M.bindings, split_nav("resize", key))
end

-- Ctrl + number to focus on <number> tab (0 = last)
for i = 1, 9 do
	table.insert(M.bindings, { key = tostring(i), mods = "CTRL", action = act.ActivateTab(i - 1) })
end
table.insert(M.bindings, { key = "0", mods = "CTRL", action = act.ActivateTab(-1) })

function M.copy_mode()
	if not wezterm.gui then
		return nil
	end
	local copy_mode = wezterm.gui.default_key_tables().copy_mode
	table.insert(copy_mode, { key = "l", mods = "SHIFT", action = act.CopyMode("MoveForwardWord") })
	table.insert(copy_mode, { key = "h", mods = "SHIFT", action = act.CopyMode("MoveBackwardWord") })
	return copy_mode
end

return M

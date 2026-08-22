-- ========================================================
-- nvim-splits
-- Wezterm <-> Neovim split-navigation key compatibility
-- ========================================================

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function is_nvim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local directions = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

function M.split_nav(resize_or_move, key)
	local mods = resize_or_move == "resize" and "META" or "CTRL"
	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(window, pane)
			if is_nvim(pane) then
				window:perform_action(act.SendKey({ key = key, mods = mods }), pane)
				return
			end
			if resize_or_move == "resize" then
				window:perform_action(act.AdjustPaneSize({ directions[key], 3 }), pane)
			else
				window:perform_action(act.ActivatePaneDirection(directions[key]), pane)
			end
		end),
	}
end

return M

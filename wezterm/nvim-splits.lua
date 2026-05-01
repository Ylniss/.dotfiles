-- ========================================================
-- nvim-splits
-- Wezterm <-> Neovim split-navigation key compatibility
-- ========================================================

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
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
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action(act.SendKey({ key = key, mods = mods }), pane)
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

return M

-- ========================================================
-- tabs
-- Tab title rendering for wezterm
-- ========================================================

local wezterm = require("wezterm")

local M = {}

local function tab_title(tab, is_windows)
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
			-- pane is PaneInformation here, cwd is a property (Url), not a method
			local cwd = pane.current_working_dir
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

function M.setup(scheme, is_windows)
	-- indexed[19] = base02, indexed[20] = base04 (builtin schemes lack indexed).
	local active_bg = (scheme.indexed and scheme.indexed[19]) or scheme.selection_bg or "#3a3a3a"
	local inactive_fg = (scheme.indexed and scheme.indexed[20]) or "#808080"

	wezterm.on("format-tab-title", function(tab)
		local outer = scheme.background
		local bg = tab.is_active and active_bg or outer
		local fg = tab.is_active and scheme.foreground or inactive_fg

		return {
			{ Background = { Color = outer } },
			{ Foreground = { Color = bg } },
			{ Text = wezterm.nerdfonts.pl_right_hard_divider },
			{ Background = { Color = bg } },
			{ Foreground = { Color = fg } },
			{ Text = " " .. tostring(tab.tab_index + 1) .. ": " .. tab_title(tab, is_windows) .. " " },
			{ Background = { Color = outer } },
			{ Foreground = { Color = bg } },
			{ Text = wezterm.nerdfonts.pl_left_hard_divider },
		}
	end)
end

return M

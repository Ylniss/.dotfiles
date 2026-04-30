-- ========================================================
-- tinty.lua
-- Builds a wezterm color-scheme from tinty's current_scheme +
-- the matching tinted-theming scheme YAML.
-- ========================================================

local M = {}

local function read_palette(yaml_path)
	local f = io.open(yaml_path, "r")
	if not f then
		return nil
	end

	local palette = {}
	local in_palette = false

	for line in f:lines() do
		if line:match("^palette:") then
			in_palette = true
		elseif in_palette then
			if line:match("^%S") then
				break
			end
			local key, value = line:match("^%s+(base%w+)%s*:%s*[\"']?(#%x+)[\"']?")
			if key and value then
				palette[key] = value
			end
		end
	end

	f:close()
	return palette
end

function M.load_tinty_scheme()
	local home = os.getenv("HOME") or ""
	local f = io.open(home .. "/.local/share/tinted-theming/tinty/current_scheme", "r")

	if not f then
		return nil
	end

	local scheme_slug = (f:read("*line") or ""):gsub("%s+$", "")
	f:close()

	local system, scheme_name = scheme_slug:match("^(base%d+)%-(.+)$")
	if not system then
		return nil
	end

	local palette = read_palette(
		string.format("%s/.local/share/tinted-theming/tinty/repos/schemes/%s/%s.yaml", home, system, scheme_name)
	)
	if not palette then
		return nil
	end

	local is_base24 = system == "base24"
	return {
		foreground = palette.base05,
		background = palette.base00,
		cursor_bg = palette.base05,
		cursor_fg = palette.base00,
		cursor_border = palette.base05,
		selection_bg = palette.base02,
		selection_fg = palette.base05,
		ansi = {
			palette.base00,
			palette.base08,
			palette.base0B,
			palette.base0A,
			palette.base0D,
			palette.base0E,
			palette.base0C,
			palette.base05,
		},
		brights = {
			palette.base03,
			is_base24 and palette.base12 or palette.base08,
			is_base24 and palette.base14 or palette.base0B,
			is_base24 and palette.base13 or palette.base0A,
			is_base24 and palette.base16 or palette.base0D,
			is_base24 and palette.base17 or palette.base0E,
			is_base24 and palette.base15 or palette.base0C,
			palette.base07,
		},
	}
end

return M

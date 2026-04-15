--- @sync entry

local function entry()
	local h = cx.active.current.hovered
	if h and h.cha.is_dir then
		ya.emit("tab_create", { tostring(h.url) })
	else
		ya.emit("tab_create", { current = true })
	end
end

return { entry = entry }

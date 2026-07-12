local run_nu = require("nu-notify").run

local get_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

local nu_snippet = [[
let cwd = $env.YAZI_DISK_CWD
let matches = (sys disks | where { |x| $cwd | str starts-with $x.mount })
if ($matches | is-empty) {
    error make { msg: $"No disk info for ($cwd)" }
}
let d = $matches.0
let used = ($d.total - $d.free)
$"Drive: ($d.mount)\nLabel: ($d.device)\nTotal: ($d.total)\nUsed:  ($used)\nFree:  ($d.free)"
]]

return {
	entry = function()
		local raw_cwd = get_cwd()
		local cwd, title
		if ya.target_family() == "windows" then
			cwd = raw_cwd:gsub("/", "\\")
			title = "Disk " .. cwd:sub(1, 2):upper()
		else
			cwd = raw_cwd
			title = "Disk"
		end

		run_nu {
			snippet = nu_snippet,
			env = { YAZI_DISK_CWD = cwd },
			error_title = "Disk info",
			success_title = title,
			timeout = 5,
		}
	end,
}

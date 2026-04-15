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
		local cwd = get_cwd():gsub("/", "\\")
		local drive = cwd:sub(1, 2):upper()

		local child, err = Command("nu")
			:arg("-c"):arg(nu_snippet)
			:env("YAZI_DISK_CWD", cwd)
			:stdout(Command.PIPED):stderr(Command.PIPED)
			:spawn()

		if not child then
			ya.notify { title = "Disk info", content = "Failed to start nu: " .. tostring(err), timeout = 5, level = "error" }
			return
		end

		local output, werr = child:wait_with_output()
		if not output then
			ya.notify { title = "Disk info", content = "wait failed: " .. tostring(werr), timeout = 5, level = "error" }
			return
		end

		if output.status.success then
			ya.notify { title = "Disk " .. drive, content = output.stdout or "", timeout = 5, level = "info" }
		else
			ya.notify {
				title = "Disk info error",
				content = "nu exit " .. tostring(output.status.code) .. ": " .. (output.stderr or ""),
				timeout = 10,
				level = "error",
			}
		end
	end,
}

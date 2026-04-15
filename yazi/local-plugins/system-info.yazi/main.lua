local nu_snippet = [[
let h = (sys host)
let cpus = (sys cpu)
let c = $cpus.0
let m = (sys mem)
let brand = ($c.brand | str replace --all --regex '\((R|TM)\)' '' | str trim)
let ncpu = ($cpus | length)

mut lines = [
  $"OS:     ($h.long_os_version)"
  $"Uptime: ($h.uptime)"
  $"CPU:    ($brand) \(($ncpu) cores\)"
]

if $nu.os-info.family == 'windows' {
  let gpu = try {
    let r = (^powershell -NoProfile -Command '(Get-CimInstance Win32_VideoController).Name -join ", "' | complete)
    if $r.exit_code == 0 { $r.stdout | str trim } else { '' }
  } catch { '' }
  if ($gpu | is-not-empty) {
    $lines ++= [$"GPU:    ($gpu)"]
  }
}

$lines ++= [$"Memory: ($m.used) / ($m.total)"]

$lines | str join "\n" | print
]]

return {
	entry = function()
		local child, err = Command("nu")
			:arg("-c"):arg(nu_snippet)
			:stdout(Command.PIPED):stderr(Command.PIPED)
			:spawn()

		if not child then
			ya.notify { title = "System info", content = "Failed to start nu: " .. tostring(err), timeout = 5, level = "error" }
			return
		end

		local output, werr = child:wait_with_output()
		if not output then
			ya.notify { title = "System info", content = "wait failed: " .. tostring(werr), timeout = 5, level = "error" }
			return
		end

		if output.status.success then
			ya.notify { title = "System", content = output.stdout or "", timeout = 6, level = "info" }
		else
			ya.notify {
				title = "System info error",
				content = "nu exit " .. tostring(output.status.code) .. ": " .. (output.stderr or ""),
				timeout = 10,
				level = "error",
			}
		end
	end,
}

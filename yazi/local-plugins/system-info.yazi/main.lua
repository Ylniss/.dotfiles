local run_nu = require("nu-notify").run

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
		run_nu {
			snippet = nu_snippet,
			error_title = "System info",
			success_title = "System",
			timeout = 6,
		}
	end,
}

-- Shared helper: run a nu snippet and show its output as a notification.
local M = {}

function M.run(opts)
	local cmd = Command("nu"):arg("-c"):arg(opts.snippet)
	for name, value in pairs(opts.env or {}) do
		cmd = cmd:env(name, value)
	end

	local child, err = cmd:stdout(Command.PIPED):stderr(Command.PIPED):spawn()
	if not child then
		ya.notify { title = opts.error_title, content = "Failed to start nu: " .. tostring(err), timeout = 5, level = "error" }
		return
	end

	local output, werr = child:wait_with_output()
	if not output then
		ya.notify { title = opts.error_title, content = "wait failed: " .. tostring(werr), timeout = 5, level = "error" }
		return
	end

	if output.status.success then
		ya.notify { title = opts.success_title, content = output.stdout or "", timeout = opts.timeout, level = "info" }
	else
		ya.notify {
			title = opts.error_title .. " error",
			content = "nu exit " .. tostring(output.status.code) .. ": " .. (output.stderr or ""),
			timeout = 10,
			level = "error",
		}
	end
end

return M

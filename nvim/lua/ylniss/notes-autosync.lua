-- Syncs the knowtes repo with its remote on first open, 30 s after the last save and on exit.
-- Failures show in Neovim and as a desktop toast, the only notice for the sync on exit.

local knowtes_path = vim.uv.fs_realpath(vim.fn.expand("~/stuff/knowtes"))
if not knowtes_path then
	return
end

local is_windows = vim.uv.os_uname().sysname:match("Windows") ~= nil

local DEBOUNCE_MS = 30000
local SYNC_WAIT_TIMEOUT_MS = 15000
local SLOW_SYNC_NOTIFY_MS = 500

local debounce_timer = assert(vim.uv.new_timer())
local sync_pending = false
local sync_running = false

-- Not `notes up` on Windows: Nushell does not hide the console window of its git child.
local sync_cmd
if is_windows then
	local cache_dir = vim.fn.stdpath("cache")
	vim.fn.mkdir(cache_dir, "p")
	sync_cmd = {
		"powershell",
		"-NoProfile",
		"-NonInteractive",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		vim.fs.joinpath(vim.fn.stdpath("config"), "scripts", "notes-autosync.ps1"),
		"-KnowtesPath",
		knowtes_path,
		"-LogPath",
		vim.fs.joinpath(cache_dir, "notes-autosync.log"),
	}
else
	sync_cmd = { "nu", "-l", "-c", "notes up" }
end

-- vim.system already hides the window; detach=true would set DETACHED_PROCESS and silently break PowerShell.
-- Sync on exit has no stderr reader once Neovim quits; a write to the closed pipe would kill it.
local function spawn_hidden(cmd, on_exit)
	vim.system(cmd, { stdout = false, stderr = on_exit ~= nil, text = true }, on_exit and vim.schedule_wrap(on_exit))
end

local function notify_failure(res)
	if res.code == 0 then
		return
	end
	vim.notify("knowtes: sync failed\n" .. vim.trim(res.stderr), vim.log.levels.ERROR)
end

local function sync_and_wait()
	local done = false
	spawn_hidden(sync_cmd, function(res)
		done = true
		notify_failure(res)
	end)
	local is_done = function()
		return done
	end
	if vim.wait(SLOW_SYNC_NOTIFY_MS, is_done) then
		return
	end
	vim.notify("knowtes: syncing…", vim.log.levels.INFO)
	vim.wait(SYNC_WAIT_TIMEOUT_MS - SLOW_SYNC_NOTIFY_MS, is_done)
end

local function in_knowtes(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	-- Check the name before the slower fs_realpath call. Autocmds call this for every file.
	if not path:lower():find("knowtes", 1, true) then
		return false
	end
	local real_path = vim.uv.fs_realpath(path)
	return real_path ~= nil and vim.startswith(real_path, knowtes_path)
end

local function trigger_sync()
	if sync_running then
		return
	end
	sync_running = true
	sync_pending = false
	spawn_hidden(sync_cmd, function(res)
		sync_running = false
		notify_failure(res)
		-- Reload any buffer whose disk file was updated by rebase.
		vim.cmd("silent! checktime")
		if sync_pending then
			trigger_sync()
		end
	end)
end

local function debounce_sync()
	debounce_timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(trigger_sync))
end

local group = vim.api.nvim_create_augroup("NotesAutosync", { clear = true })

vim.api.nvim_create_autocmd("BufReadPre", {
	group = group,
	callback = function(ev)
		if not in_knowtes(ev.buf) then
			return
		end
		sync_and_wait()
		-- Without this, :wq on an unmodified buffer warns about an external change.
		vim.schedule(function()
			vim.cmd("silent! checktime")
		end)
		return true
	end,
	desc = "knowtes: sync before first file read (prevents stale overwrite)",
})

vim.api.nvim_create_autocmd("BufWritePost", {
	group = group,
	callback = function(ev)
		if not in_knowtes(ev.buf) then
			return
		end
		sync_pending = true
		debounce_sync()
	end,
	desc = "knowtes: debounce-schedule sync after save",
})

vim.api.nvim_create_autocmd("VimLeavePre", {
	group = group,
	callback = function()
		if not sync_pending then
			return
		end
		debounce_timer:stop()
		spawn_hidden(sync_cmd)
	end,
	desc = "knowtes: flush pending sync on exit",
})

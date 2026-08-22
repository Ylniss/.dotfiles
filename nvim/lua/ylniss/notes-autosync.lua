-- Auto-syncs knowtes repo with remote:
--   * pull on first file opened
--   * 30s-debounced sync after save
--   * flush on :wq
--
-- Failure toasts need per-OS deps:
--   linux:   notify-send            (apt install libnotify-bin)
--   macos:   osascript              (built-in)
--   windows: BurntToast             (Install-Module BurntToast)
--   android: termux-notification    (pkg install termux-api)

local knowtes_path = vim.uv.fs_realpath(vim.fn.expand("~/stuff/knowtes"))
if not knowtes_path then
	return
end

local is_windows = vim.uv.os_uname().sysname:match("Windows") ~= nil

local DEBOUNCE_MS = 30000
local SYNC_TIMEOUT_MS = 15000
local SLOW_SYNC_NOTIFY_MS = 500

local debounce_timer
local sync_pending = false
local sync_in_flight = false
local pulled_this_session = false

local function read_file(path)
	local f = io.open(path, "rb")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

local function write_if_changed(path, content)
	if read_file(path) == content then
		return
	end
	local f = io.open(path, "wb")
	if not f then
		return
	end
	f:write(content)
	f:close()
end

-- Windows uses a PS script, not `notes up`: nushell doesn't hide child
-- git's console window on Windows. Log at stdpath/cache/notes-autosync.log.
local sync_cmd
if is_windows then
	local cache_dir = vim.fn.stdpath("cache")
	vim.fn.mkdir(cache_dir, "p")
	local sync_ps_path = vim.fs.joinpath(cache_dir, "notes-autosync.ps1")
	local log_path = vim.fs.joinpath(cache_dir, "notes-autosync.log")
	local escaped_notes_path = knowtes_path:gsub("'", "''")
	local escaped_log_path = log_path:gsub("'", "''")
	local sync_script = vim.trim(string.format(
		[[
$log = '%s'
$utf8 = [System.Text.Encoding]::UTF8
function Log($msg) {
  try { [System.IO.File]::AppendAllText($log, "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg`r`n", $utf8) } catch {}
}
function Fail($msg) {
  Log "FAIL: $msg"
  if (Get-Module -ListAvailable BurntToast) {
    New-BurntToastNotification -Text 'notes-autosync', $msg
  }
  exit 1
}
function Git($name, $cmdArgs) {
  $out = & git.exe @cmdArgs 2>&1
  if ($out) {
    try { [System.IO.File]::AppendAllText($log, ($out -join "`r`n") + "`r`n", $utf8) } catch {}
  }
  if ($LASTEXITCODE -ne 0) { Fail "$name failed" }
}
function GitOut($name, $cmdArgs) {
  $out = & git.exe @cmdArgs 2>$null
  if ($LASTEXITCODE -ne 0) { Fail "$name failed" }
  return $out
}
try {
  if ((Test-Path $log) -and (Get-Item $log).Length -gt 500KB) {
    $tail = Get-Content $log -Tail 500
    [System.IO.File]::WriteAllLines($log, $tail, $utf8)
  }
} catch {}
Log '--- sync start ---'
try { Set-Location '%s' } catch { Fail "cd failed: $_" }
Git 'fetch' @('fetch', '--quiet')
$branch = (GitOut 'rev-parse' @('rev-parse', '--abbrev-ref', 'HEAD')).Trim()
$upstream = "origin/$branch"
$dirty = GitOut 'status' @('status', '--porcelain')
if ($dirty) {
  Log 'staging changes'
  Git 'add' @('add', '.')
  Git 'commit' @('commit', '--quiet', '-m', 'update')
}
$behind = [int]((GitOut 'behind-count' @('rev-list', '--count', "HEAD..$upstream")).Trim())
if ($behind -gt 0) {
  Log "rebasing ($behind behind)"
  Git 'rebase' @('rebase', '--quiet', $upstream)
}
$ahead = [int]((GitOut 'ahead-count' @('rev-list', '--count', "$upstream..HEAD")).Trim())
if ($ahead -gt 0) {
  Log "pushing ($ahead ahead)"
  Git 'push' @('push', '--quiet')
}
Log "--- sync done (ahead=$ahead, behind=$behind) ---"
]],
		escaped_log_path,
		escaped_notes_path
	)) .. "\n"
	write_if_changed(sync_ps_path, sync_script)
	sync_cmd = {
		"powershell",
		"-NoProfile",
		"-NonInteractive",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		sync_ps_path,
	}
else
	sync_cmd = { "nu", "-l", "-c", "notes up" }
end

-- hide=true sets CREATE_NO_WINDOW so git.exe doesn't flash. Don't add
-- detached=true — it sets DETACHED_PROCESS which silently breaks PowerShell.
local function spawn_hidden(cmd_args, on_exit)
	local handle
	---@diagnostic disable-next-line: missing-fields
	handle = vim.uv.spawn(cmd_args[1], {
		args = vim.list_slice(cmd_args, 2),
		hide = true,
		stdio = { nil, nil, nil },
	}, function()
		handle:close()
		if on_exit then
			vim.schedule(on_exit)
		end
	end)
	if not handle and on_exit then
		vim.schedule(on_exit)
	end
end

-- Blocks until sync exits (or timeout). Used at BufReadPre so the file is
-- read from disk AFTER rebase lands — otherwise a save could push an old
-- version over the remote. Notifies if the sync runs long so user knows why
-- nvim is hanging.
local function sync_and_wait(timeout_ms)
	local done = false
	local slow_timer = assert(vim.uv.new_timer())
	slow_timer:start(
		SLOW_SYNC_NOTIFY_MS,
		0,
		vim.schedule_wrap(function()
			if not done then
				vim.notify("knowtes: syncing…", vim.log.levels.INFO)
			end
		end)
	)
	spawn_hidden(sync_cmd, function()
		done = true
	end)
	vim.wait(timeout_ms, function()
		return done
	end)
	slow_timer:stop()
	slow_timer:close()
end

local function cancel_debounce()
	if debounce_timer then
		debounce_timer:stop()
		debounce_timer:close()
		debounce_timer = nil
	end
end

local function in_knowtes(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then
		return false
	end
	-- Fast reject before realpath syscall (runs on every save anywhere).
	if not path:lower():find("knowtes", 1, true) then
		return false
	end
	local real_path = vim.uv.fs_realpath(path)
	return real_path ~= nil and vim.startswith(real_path, knowtes_path)
end

local function trigger_sync()
	if sync_in_flight then
		return
	end
	sync_in_flight = true
	sync_pending = false
	spawn_hidden(sync_cmd, function()
		sync_in_flight = false
		-- Reload any buffer whose disk file was updated by rebase.
		vim.cmd("silent! checktime")
		if sync_pending then
			trigger_sync()
		end
	end)
end

local function debounce_sync()
	cancel_debounce()
	debounce_timer = assert(vim.uv.new_timer())
	debounce_timer:start(
		DEBOUNCE_MS,
		0,
		vim.schedule_wrap(function()
			cancel_debounce()
			trigger_sync()
		end)
	)
end

local group = vim.api.nvim_create_augroup("NotesAutosync", { clear = true })

vim.api.nvim_create_autocmd("BufReadPre", {
	group = group,
	callback = function(ev)
		if not in_knowtes(ev.buf) then
			return
		end
		if pulled_this_session then
			return
		end
		pulled_this_session = true
		sync_and_wait(SYNC_TIMEOUT_MS)
		-- Re-stat after BufReadPost so the buffer's stored mtime matches the
		-- synced file. Without this, :wq on an unmodified buffer warns about
		-- external change.
		vim.schedule(function()
			vim.cmd("silent! checktime")
		end)
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
		cancel_debounce()
		spawn_hidden(sync_cmd)
	end,
	desc = "knowtes: flush pending sync on exit",
})

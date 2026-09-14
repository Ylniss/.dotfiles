-- Syncs the knowtes repo with its remote:
--   * sync before the first knowtes file opens
--   * sync 30 s after the last save
--   * on exit, run a pending sync
--
-- Failure notifications need one tool per OS:
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
local SYNC_WAIT_TIMEOUT_MS = 15000
local SLOW_SYNC_NOTIFY_MS = 500

local debounce_timer = assert(vim.uv.new_timer())
local sync_pending = false
local sync_running = false

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

-- On Windows, run a PowerShell script, not `notes up`.
-- Nushell does not hide the console window of its git child process.
local sync_cmd
if is_windows then
	local cache_dir = vim.fn.stdpath("cache")
	vim.fn.mkdir(cache_dir, "p")
	local sync_script_path = vim.fs.joinpath(cache_dir, "notes-autosync.ps1")
	local log_path = vim.fs.joinpath(cache_dir, "notes-autosync.log")
	local escaped_knowtes_path = knowtes_path:gsub("'", "''")
	local escaped_log_path = log_path:gsub("'", "''")
	local sync_script = string.format(
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
		escaped_knowtes_path
	)
	write_if_changed(sync_script_path, sync_script)
	sync_cmd = {
		"powershell",
		"-NoProfile",
		"-NonInteractive",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		sync_script_path,
	}
else
	sync_cmd = { "nu", "-l", "-c", "notes up" }
end

-- vim.system spawns with hide=true (CREATE_NO_WINDOW) so git.exe doesn't flash.
-- Don't add detach=true — it sets DETACHED_PROCESS which silently breaks PowerShell.
local function spawn_hidden(cmd, on_exit)
	vim.system(cmd, { stdout = false, stderr = false }, on_exit and vim.schedule_wrap(on_exit))
end

-- Start a sync and wait until it exits. Stop waiting after timeout_ms.
-- BufReadPre calls this, so Neovim reads the file after the rebase.
-- Without this wait, a save can push an old version over the remote.
local function sync_and_wait(timeout_ms)
	local done = false
	spawn_hidden(sync_cmd, function()
		done = true
	end)
	local is_done = function()
		return done
	end
	if vim.wait(SLOW_SYNC_NOTIFY_MS, is_done) then
		return
	end
	vim.notify("knowtes: syncing…", vim.log.levels.INFO)
	vim.wait(timeout_ms - SLOW_SYNC_NOTIFY_MS, is_done)
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
	spawn_hidden(sync_cmd, function()
		sync_running = false
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
		sync_and_wait(SYNC_WAIT_TIMEOUT_MS)
		-- After the read, update the buffer's stored mtime to match the synced file.
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

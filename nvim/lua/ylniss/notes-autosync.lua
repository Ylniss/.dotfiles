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
if not knowtes_path then return end

local is_windows = vim.uv.os_uname().sysname:match("Windows") ~= nil

local DEBOUNCE_MS = 30000

local debounce_timer
local dirty = false
local sync_in_flight = false
local pulled_this_session = false

-- Windows uses a PS script, not `notes up`: nushell doesn't hide child
-- git's console window on Windows. Log at stdpath/cache/notes-autosync.log.
local sync_cmd
if is_windows then
	local cache_dir = vim.fn.stdpath("cache")
	vim.fn.mkdir(cache_dir, "p")
	local sync_ps_path = vim.fs.joinpath(cache_dir, "notes-autosync.ps1")
	local log_path = vim.fs.joinpath(cache_dir, "notes-autosync.log")
	local esc_notes = knowtes_path:gsub("'", "''")
	local esc_log = log_path:gsub("'", "''")
	local sync_script = string.format([[
$log = '%s'
function Log($msg) {
  "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" | Out-File -FilePath $log -Append -Encoding utf8
}
function Fail($msg) {
  Log "FAIL: $msg"
  if (Get-Module -ListAvailable BurntToast) {
    New-BurntToastNotification -Text 'notes-autosync', $msg
  }
  exit 1
}
Log '--- sync start ---'
try { Set-Location '%s' } catch { Fail "cd failed: $_" }
Log "cwd=$PWD"
& git fetch --quiet 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
Log "fetch done, exit=$LASTEXITCODE"
if ($LASTEXITCODE -ne 0) { Fail 'fetch failed' }
$branch = (& git rev-parse --abbrev-ref HEAD).Trim()
if ($LASTEXITCODE -ne 0) { Fail 'rev-parse failed' }
$upstream = "origin/$branch"
$dirty = & git status --porcelain
if ($LASTEXITCODE -ne 0) { Fail 'status failed' }
if ($dirty) {
  Log 'staging changes'
  & git add . 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
  if ($LASTEXITCODE -ne 0) { Fail 'add failed' }
  & git commit --quiet -m 'update' 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
  if ($LASTEXITCODE -ne 0) { Fail 'commit failed' }
  Log 'commit ok'
}
$behind = [int](((& git rev-list --count "HEAD..$upstream") -join '').Trim())
if ($LASTEXITCODE -ne 0) { Fail 'behind-count failed' }
if ($behind -gt 0) {
  Log "rebasing ($behind behind)"
  & git rebase --quiet $upstream 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
  if ($LASTEXITCODE -ne 0) { Fail 'rebase failed - resolve manually' }
}
$ahead = [int](((& git rev-list --count "$upstream..HEAD") -join '').Trim())
if ($LASTEXITCODE -ne 0) { Fail 'ahead-count failed' }
if ($ahead -gt 0) {
  Log "pushing ($ahead ahead)"
  & git push --quiet 2>&1 | Out-File -FilePath $log -Append -Encoding utf8
  if ($LASTEXITCODE -ne 0) { Fail 'push failed' }
}
Log "--- sync done (ahead=$ahead, behind=$behind) ---"
]], esc_log, esc_notes)
	vim.fn.writefile(vim.split(sync_script, "\n"), sync_ps_path)
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
local function spawn_quiet(cmd_args, on_exit)
	local handle
	handle = vim.uv.spawn(cmd_args[1], {
		args = { unpack(cmd_args, 2) },
		hide = true,
		stdio = { nil, nil, nil },
	}, function(_code, _signal)
		handle:close()
		if on_exit then vim.schedule(on_exit) end
	end)
	if not handle then
		if on_exit then vim.schedule(on_exit) end
		return
	end
end

local function cancel_timer()
	if debounce_timer then
		debounce_timer:stop()
		debounce_timer:close()
		debounce_timer = nil
	end
end

local function in_knowtes(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then return false end
	local real = vim.uv.fs_realpath(path)
	if not real then return false end
	return vim.startswith(real, knowtes_path)
end

local function trigger_sync()
	if sync_in_flight then return end
	sync_in_flight = true
	dirty = false
	spawn_quiet(sync_cmd, function()
		sync_in_flight = false
		if dirty then trigger_sync() end
	end)
end

local function debounce_sync()
	cancel_timer()
	debounce_timer = vim.uv.new_timer()
	debounce_timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
		cancel_timer()
		trigger_sync()
	end))
end

local group = vim.api.nvim_create_augroup("NotesAutosync", { clear = true })

vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	callback = function(ev)
		if not in_knowtes(ev.buf) then return end
		if pulled_this_session then return end
		pulled_this_session = true
		trigger_sync()
	end,
	desc = "knowtes: pull on first buffer read this session",
})

vim.api.nvim_create_autocmd("BufWritePost", {
	group = group,
	callback = function(ev)
		if not in_knowtes(ev.buf) then return end
		dirty = true
		debounce_sync()
	end,
	desc = "knowtes: debounce-schedule sync after save",
})

vim.api.nvim_create_autocmd("VimLeavePre", {
	group = group,
	callback = function()
		if not dirty then return end
		cancel_timer()
		spawn_quiet(sync_cmd)
	end,
	desc = "knowtes: flush pending sync on exit",
})

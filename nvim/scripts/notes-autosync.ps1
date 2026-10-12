param($KnowtesPath, $LogPath)
$utf8 = [System.Text.Encoding]::UTF8
function Log($msg) {
  try { [System.IO.File]::AppendAllText($LogPath, "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg`r`n", $utf8) } catch {}
}
function Fail($msg) {
  Log "FAIL: $msg"
  [Console]::Error.WriteLine($msg)
  if (Get-Module -ListAvailable BurntToast) {
    New-BurntToastNotification -Text 'notes-autosync', $msg
  }
  exit 1
}
function Git($name, $cmdArgs) {
  $out = & git.exe @cmdArgs 2>&1
  if ($out) {
    try { [System.IO.File]::AppendAllText($LogPath, ($out -join "`r`n") + "`r`n", $utf8) } catch {}
  }
  if ($LASTEXITCODE -ne 0) { Fail "$name failed: $($out | Select-Object -First 1)" }
}
function GitOut($name, $cmdArgs) {
  $out = & git.exe @cmdArgs 2>$null
  if ($LASTEXITCODE -ne 0) { Fail "$name failed" }
  return $out
}
try {
  if ((Test-Path $LogPath) -and (Get-Item $LogPath).Length -gt 500KB) {
    $tail = Get-Content $LogPath -Tail 500
    [System.IO.File]::WriteAllLines($LogPath, $tail, $utf8)
  }
} catch {}
Log '--- sync start ---'
try { Set-Location $KnowtesPath } catch { Fail "cd failed: $_" }
# A sync takes seconds, so an older lock was left by a killed git.
$lock = '.git/index.lock'
if ((Test-Path $lock) -and (Get-Item $lock).LastWriteTime -lt (Get-Date).AddMinutes(-5)) {
  Log 'removing stale index.lock'
  Remove-Item $lock
}
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

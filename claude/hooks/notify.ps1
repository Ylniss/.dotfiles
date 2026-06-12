# Claude Code hook: Windows toast for Notification and Stop events.
# Reads the hook JSON from stdin. Non-blocking, auto-dismisses.

$payload = try { [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { $null }

$project = if ($payload -and $payload.cwd) { Split-Path -Leaf $payload.cwd } else { 'Claude Code' }
$text = if ($payload -and $payload.hook_event_name -eq 'Stop') {
    'Finished responding'
} elseif ($payload -and $payload.message) {
    $payload.message
} else {
    'Needs your attention'
}

# WinRT toast API — requires Windows PowerShell 5.1 (powershell.exe), not pwsh.
[void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
[void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

$title = [System.Security.SecurityElement]::Escape("Claude Code - $project")
$body = [System.Security.SecurityElement]::Escape($text)
$doc = New-Object Windows.Data.Xml.Dom.XmlDocument
$doc.LoadXml("<toast><visual><binding template=`"ToastGeneric`"><text>$title</text><text>$body</text></binding></visual></toast>")

# powershell.exe's registered AppUserModelID — toasts need one to display.
$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show(
    [Windows.UI.Notifications.ToastNotification]::new($doc))

# Cross-platform toast. Silent if OS tool missing.
#   linux:   notify-send            (apt install libnotify-bin)
#   macos:   osascript              (built-in)
#   windows: BurntToast             (Install-Module BurntToast)
#   android: termux-notification    (pkg install termux-api)

def notify [title: string, message: string] {
  if (is-windows) {
    let t = ($title | str replace --all "'" "''")
    let m = ($message | str replace --all "'" "''")
    try { powershell -NoProfile -Command $"New-BurntToastNotification -Text '($t)', '($m)'" }
  } else if (is-macos) {
    let t = ($title | str replace --all '"' '\"')
    let m = ($message | str replace --all '"' '\"')
    try { osascript -e $'display notification "($m)" with title "($t)"' }
  } else if (is-android) {
    try { termux-notification --title $title --content $message }
  } else {
    try { notify-send $title $message }
  }
}

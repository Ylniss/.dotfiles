# Silent no-op without the toaster: libnotify-bin (linux), BurntToast module (windows), termux-api (android)
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

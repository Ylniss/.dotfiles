#!/usr/bin/env nu

let lock_script = ($env.HOME | path join ".config/swaylock/lock.nu")

let entries = [
    { label: "󰌾  Lock",     cmd: [$lock_script] }
    { label: "󰜉  Reboot",   cmd: [systemctl reboot] }
    { label: "󰐥  Shutdown", cmd: [systemctl poweroff] }
    { label: "󰍃  Logout",   cmd: [niri msg action quit] }
]

let choice = (
    $entries
    | get label
    | str join (char nl)
    | fuzzel --dmenu
    | str trim
)

let picked = ($entries | where label == $choice | get 0?)
if $picked != null {
    exec ...$picked.cmd
}

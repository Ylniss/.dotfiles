#!/usr/bin/env nu

let choice = (
    "󰌾  Lock\n󰜉  Reboot\n󰐥  Shutdown\n󰍃  Logout"
    | fuzzel --dmenu
    | str trim
)

let lock_script = ($env.HOME | path join ".config/swaylock/lock.nu")

match $choice {
    "󰌾  Lock"     => { exec $lock_script }
    "󰜉  Reboot"   => { exec systemctl reboot }
    "󰐥  Shutdown" => { exec systemctl poweroff }
    "󰍃  Logout"   => { exec niri msg action quit }
}

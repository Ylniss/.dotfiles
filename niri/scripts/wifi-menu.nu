#!/usr/bin/env nu
# Wi-Fi picker via fuzzel + nmcli.
# Shows the cached scan instantly; a background rescan refreshes the cache for next time.
# Saved networks reconnect directly; new secured ones prompt for a password.
# Enterprise (802.1x) bails out — use nmtui for those.
# Second invocation while the menu is open closes it (toggle).

const PROMPT          = "󰖩  "
const FZ_CACHE        = "/tmp/wifi-menu-fz.cache"
const TOGGLE_PATTERN  = "fuzzel.*wifi-menu-fz"

const ACT_RESCAN      = "󰑐  Rescan"
const ACT_DISCONNECT  = "󰖪  Disconnect"
const ACT_WIFI_OFF    = "󰖪  Turn Wi-Fi off"
const ACT_WIFI_ON     = "󰖩  Turn Wi-Fi on"

def notify [title: string, body: string = ""] {
    try { ^notify-send -a wifi-menu $title $body }
}

def signal-icon [pct: int]: nothing -> string {
    match $pct {
        0..10  => "󰤯"
        11..40 => "󰤟"
        41..60 => "󰤢"
        61..80 => "󰤥"
        _      => "󰤨"
    }
}

# nmcli --terse uses ':' as separator and escapes ':' and '\' with backslashes.
# Encode escape sequences to control bytes, split on ':', then decode in fields.
def nm-decode [s: string]: nothing -> string {
    $s | str replace -a "\u{02}" ":" | str replace -a "\u{01}" '\'
}

def nm-parse [line: string]: nothing -> list<string> {
    $line
    | str replace -ar '\\\\' "\u{01}"
    | str replace -ar '\\:' "\u{02}"
    | split row ':'
}

def nm-list [rescan: string]: nothing -> table {
    let raw = (try { ^nmcli -t -f "IN-USE,SSID,SECURITY,SIGNAL" device wifi list --rescan $rescan } catch { "" })
    $raw
    | lines
    | where { |l| $l != "" }
    | each { |line|
        let parts = (nm-parse $line)
        {
            in_use:   ($parts | get 0? | default ""),
            ssid:     (nm-decode ($parts | get 1? | default "")),
            security: ($parts | get 2? | default ""),
            signal:   ($parts | get 3? | default "0" | into int),
        }
    }
    | where ssid != ""
    | uniq-by ssid
}

def fuzzel-pick [items: list<string>, prompt: string]: nothing -> any {
    try {
        ($items | str join "\n") + "\n"
        | ^fuzzel --dmenu --prompt $prompt --cache $FZ_CACHE
        | str trim --right
    }
}

def fuzzel-password [prompt: string]: nothing -> any {
    try {
        ^fuzzel --dmenu --password --prompt $prompt --cache $FZ_CACHE | str trim
    }
}

def with-scanning-indicator [task: closure]: nothing -> any {
    let id = try {
        ^notify-send -a wifi-menu --print-id "Wi-Fi" "Scanning…" | str trim | into int
    } catch { 0 }
    let result = (do $task)
    if $id > 0 {
        ^notify-send -a wifi-menu --replace-id $id --expire-time 1 " " " " | complete | ignore
    }
    $result
}

def is-open [security: string]: nothing -> bool {
    $security in ["" "--"]
}

def saved-profile-exists [ssid: string]: nothing -> bool {
    let names = (try { ^nmcli -g NAME connection show | lines } catch { [] })
    $ssid in $names
}

def report [title: string, result: record] {
    if $result.exit_code == 0 {
        notify "Wi-Fi" $title
    } else {
        notify "Wi-Fi failed" ($result.stderr | str trim)
    }
}

def main [--rescan(-r)] {
    # Toggle: if a previous menu is still open, close it and exit.
    if not $rescan {
        let already_open = ((^pgrep -f $TOGGLE_PATTERN | complete | get exit_code) == 0)
        if $already_open {
            ^pkill -f $TOGGLE_PATTERN
            return
        }
    }

    let radio = (try { ^nmcli -t -f WIFI radio | str trim } catch { "enabled" })
    if $radio == "disabled" {
        let pick = (fuzzel-pick [$ACT_WIFI_ON] $PROMPT)
        if $pick == $ACT_WIFI_ON {
            ^nmcli radio wifi on
            notify "Wi-Fi" "Enabled"
        }
        return
    }

    # Kick off a refresh so the cache is fresh next time. Rate-limit errors are fine.
    if not $rescan {
        job spawn { try { ^nmcli device wifi rescan | ignore } } | ignore
    }

    let initial = if $rescan {
        with-scanning-indicator { nm-list "yes" }
    } else {
        nm-list "no"
    }
    let nets = if (($initial | is-empty) and (not $rescan)) {
        # First run after boot — nothing cached. Pay the scan cost once.
        with-scanning-indicator { nm-list "yes" }
    } else {
        $initial
    }

    let connected = ($nets | where in_use == "*")
    let active = if ($connected | is-empty) { "" } else { $connected | first | get ssid }

    let menu_table = ($nets | each { |n|
        let lock = if (is-open $n.security) { " " } else { "󰌾" }
        let display = $"  (signal-icon $n.signal)  ($lock)  ($n.ssid)"
        { display: $display, ssid: $n.ssid, security: $n.security }
    })

    let menu_items = [
        ...($menu_table | get display)
        $ACT_RESCAN
        ...(if $active != "" { [$ACT_DISCONNECT] } else { [] })
        $ACT_WIFI_OFF
    ]

    let pick = (fuzzel-pick $menu_items $PROMPT)
    if $pick == null { return }

    if $pick == $ACT_RESCAN {
        main --rescan
        return
    }
    if $pick == $ACT_DISCONNECT {
        let r = (^nmcli connection down id $active | complete)
        report $"Disconnected from ($active)" $r
        return
    }
    if $pick == $ACT_WIFI_OFF {
        ^nmcli radio wifi off
        notify "Wi-Fi" "Disabled"
        return
    }

    let entry = ($menu_table | where display == $pick | get 0?)
    if $entry == null { return }
    let ssid = $entry.ssid

    if $ssid == $active {
        notify "Wi-Fi" $"Already connected to ($ssid)"
        return
    }

    let is_enterprise = (($entry.security | str contains "802.1X") or ($entry.security | str contains "EAP"))
    if $is_enterprise {
        notify "Wi-Fi" "Enterprise network — configure with nmtui"
        return
    }

    let is_open = (is-open $entry.security)

    if (saved-profile-exists $ssid) {
        let r = (^nmcli --wait 10 connection up id $ssid | complete)
        if $r.exit_code == 0 {
            notify "Wi-Fi" $"Connected to ($ssid)"
            return
        }
        if $is_open {
            notify "Wi-Fi failed" ($r.stderr | str trim)
            return
        }
        # Saved profile failed for a secured network — fall through to re-prompt.
    }

    if $is_open {
        let r = (^nmcli --wait 15 device wifi connect $ssid | complete)
        report $"Connected to ($ssid)" $r
        return
    }

    let password = (fuzzel-password $"󰌾  ($ssid): ")
    if (($password == null) or ($password == "")) { return }

    let r = (^nmcli --wait 15 device wifi connect $ssid password $password | complete)
    report $"Connected to ($ssid)" $r
}

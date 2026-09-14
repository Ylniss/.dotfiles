# niri disables the touchpad while this override file exists, and live-reloads on change.
# The main config includes it with `optional=true`, so a missing file means touchpad on.
const TOUCHPAD_OVERRIDE = ("~/.config/niri/touchpad-off.kdl" | path expand)

# The change stays after a reboot.
# niri cannot hide the cursor permanently. With the touchpad off the cursor does not move,
# so --hide-cursor sets a 1 ms idle timeout, and the cursor stays hidden.
def "touchpad off" [--hide-cursor] {
  mut config = r#'// Written by the `touchpad off` command. Remove it with `touchpad on`.
input {
    touchpad {
        off
    }
}
'#
  if $hide_cursor {
    $config += r#'
cursor {
    hide-after-inactive-ms 1
}
'#
  }
  $config | save --force $TOUCHPAD_OVERRIDE
}

def "touchpad on" [] {
  rm --force $TOUCHPAD_OVERRIDE
}

# niri disables the touchpad while this override file exists, and live-reloads on change.
# The main config includes it with `optional=true`, so a missing file means touchpad on.
const TOUCHPAD_OVERRIDE = ("~/.config/niri/touchpad-off.kdl" | path expand)

# Persists across reboots. --hide-cursor also hides the pointer: niri has no permanent
# hide, but with the touchpad off the cursor stops moving, so a 1 ms idle timeout sticks.
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

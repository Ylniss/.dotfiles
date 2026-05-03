#!/usr/bin/env nu

# Toggle a floating foot window running a given command.
# Usage: toggle-floating-window-with-foot.nu <app-id> [--size WxH] <cmd> [args...]
def --wrapped main [
    app_id: string,
    --size: string = "",
    ...cmd: string,
] {
    let pattern = $"foot --app-id=($app_id)"

    if (^pgrep -f $pattern | complete | get exit_code) == 0 {
        ^pkill -f $pattern
    } else {
        let app_arg = $"--app-id=($app_id)"
        if ($size == "") {
            ^foot $app_arg ...$cmd
        } else {
            ^foot $app_arg $"--window-size-chars=($size)" ...$cmd
        }
    }
}

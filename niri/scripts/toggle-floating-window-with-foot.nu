#!/usr/bin/env nu

# Toggle a floating foot window running a given command.
# Usage: toggle-floating-window-with-foot.nu <app-id> [--size WxH] <cmd> [args...]
def --wrapped main [
    app_id: string,
    --size: string,
    ...cmd: string,
] {
    let app_arg = $"--app-id=($app_id)"
    let pattern = $"foot ($app_arg)"

    if (^pgrep -f $pattern | complete | get exit_code) == 0 {
        ^pkill -f $pattern
    } else {
        let size_arg = if $size == null { [] } else { [$"--window-size-chars=($size)"] }
        ^foot $app_arg ...$size_arg ...$cmd
    }
}

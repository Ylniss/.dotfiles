#!/usr/bin/env nu
# Toggle a floating foot window running btop.

const PATTERN = "foot --app-id=btop-float"

if (^pgrep -f $PATTERN | complete | get exit_code) == 0 {
    ^pkill -f $PATTERN
} else {
    ^foot --app-id=btop-float --window-size-chars=100x35 btop 
}


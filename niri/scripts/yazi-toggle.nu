#!/usr/bin/env nu
# Toggle a floating foot window running yazi.

const PATTERN = "foot --app-id=yazi-float"

if (^pgrep -f $PATTERN | complete | get exit_code) == 0 {
    ^pkill -f $PATTERN
} else {
    ^foot --app-id=yazi-float --window-size-chars=110x35 yazi 
}

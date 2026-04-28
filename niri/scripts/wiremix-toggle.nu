#!/usr/bin/env nu
# Toggle a floating foot window running wiremix.

const PATTERN = "foot --app-id=wiremix-float"

if (^pgrep -f $PATTERN | complete | get exit_code) == 0 {
    ^pkill -f $PATTERN
} else {
    ^foot --app-id=wiremix-float wiremix -v output
}

#!/bin/sh

PATTERN='foot --app-id=wiremix-float'

if pgrep -f "$PATTERN" >/dev/null; then
    pkill -f "$PATTERN"
else
    exec foot --app-id=wiremix-float wiremix -v output
fi

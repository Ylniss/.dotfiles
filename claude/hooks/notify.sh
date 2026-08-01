#!/usr/bin/env bash
# Claude Code hook: desktop notification for Notification and Stop events.
# Reads the hook JSON from stdin and dispatches to the platform notifier.

set -euo pipefail

case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    # MSYS converts the path argument to Windows form.
    exec powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden \
      -File "$HOME/.claude/hooks/notify.ps1"
    ;;
esac

payload=$(cat)

cwd=$(jq -r '.cwd // empty' <<<"$payload")
project=${cwd:+$(basename "$cwd")}
project=${project:-Claude Code}

event=$(jq -r '.hook_event_name // empty' <<<"$payload")
message=$(jq -r '.message // empty' <<<"$payload")

if [[ $event == Stop ]]; then
  text='Finished responding'
elif [[ -n $message ]]; then
  text=$message
else
  text='Needs your attention'
fi

notify-send -a 'Claude Code' "Claude Code - $project" "$text"

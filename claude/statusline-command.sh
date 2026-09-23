#!/usr/bin/env bash
# Claude Code status line — model, context, project, rate limits

# One value per line — robust against Windows jq.exe (CRLF) and avoids
# whitespace-IFS collapsing of consecutive empty TSV fields.
{
    IFS= read -r cwd
    IFS= read -r model
    IFS= read -r used_pct
    IFS= read -r five_h_pct
    IFS= read -r five_h_reset
    IFS= read -r week_pct
    IFS= read -r week_reset
} < <(jq -r '
    .workspace.current_dir // .cwd,
    .model.display_name,
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // "")
' | tr -d '\r')
model="${model% (*)}"

# --- Colors (ANSI named — follow terminal palette, like starship.toml)
BRIGHT_WHITE_ITALIC=$'[3;97m'       # directory
DIM=$'[2;37m'
DIM_ITALIC=$'[2;3;37m'
BOLD=$'[1m'
BLUE=$'[94m'
RST=$'[0m'

# --- Directory
# In a repo: just the repo root name. Otherwise: full path, with $HOME → ~
if repo_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null) && [ -n "$repo_root" ]; then
    short_dir="${repo_root##*/}"
else
    home=$HOME
    if [ "$cwd" = "$home" ]; then
        short_dir="~"
    elif [ "${cwd#$home/}" != "$cwd" ]; then
        short_dir="~/${cwd#$home/}"
    else
        short_dir="$cwd"
    fi
fi

# --- Reset-time formatter (Pro/Max rate-limit windows)
fmt_reset() {
    local target=$1
    local now=$(date +%s)
    local diff=$((target - now))
    [ "$diff" -le 0 ] && { echo "0m"; return; }
    local d=$((diff / 86400))
    local h=$(( (diff % 86400) / 3600 ))
    local m=$(( (diff % 3600) / 60 ))
    if   [ "$d" -gt 0 ]; then echo "${d}d ${h}h"
    elif [ "$h" -gt 0 ]; then echo "${h}h ${m}m"
    else                      echo "${m}m"
    fi
}

# --- Assemble: model + sections, joined by " | "
printf '%s%s%s' "$DIM" "$model" "$RST"

need_sep=0
emit_sep() {
    if [ "$need_sep" = "1" ]; then
        printf '%s | %s' "$DIM" "$RST"
    else
        printf ' '
        need_sep=1
    fi
}

emit_section() {
    local label=$1 value=$2 suffix=$3
    emit_sep
    printf '%s%s%s %s%s%%%s' "$BOLD" "$label" "$RST" "$BLUE" "$value" "$RST"
    [ -n "$suffix" ] && printf ' %s%s%s' "$DIM_ITALIC" "$suffix" "$RST"
}

if [ -n "$used_pct" ]; then
    ctx_int=$(printf '%.0f' "$used_pct")
    emit_section "ctx" "$ctx_int" ""
fi
emit_sep
printf '%s%s%s' "$BRIGHT_WHITE_ITALIC" "$short_dir" "$RST"
if [ -n "$five_h_pct" ]; then
    five_int=$(printf '%.0f' "$five_h_pct")
    suffix=""
    [ -n "$five_h_reset" ] && suffix=$(fmt_reset "$five_h_reset")
    emit_section "5h" "$five_int" "$suffix"
fi
if [ -n "$week_pct" ]; then
    week_int=$(printf '%.0f' "$week_pct")
    suffix=""
    [ -n "$week_reset" ] && suffix=$(fmt_reset "$week_reset")
    emit_section "7d" "$week_int" "$suffix"
fi

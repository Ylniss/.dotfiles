#!/usr/bin/env bash
# Claude Code status line — mirrors Starship prompt key elements

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- Colors (ANSI named — follow terminal palette, like starship.toml)
GREEN=$'\033[32m'                       # git staged
YELLOW=$'\033[33m'                      # git modified
WHITE=$'\033[37m'                       # git untracked
RED=$'\033[31m'                         # "in ", git branch
BOLD_RED=$'\033[1;31m'                  # git ahead/behind (git_status default style)
BRIGHT_WHITE=$'\033[97m'                # username
BRIGHT_WHITE_ITALIC=$'\033[3;97m'       # directory
DIM=$'\033[2;37m'
BOLD=$'\033[1m'
BLUE=$'\033[94m'
RST=$'\033[0m'

# --- User
user=$(whoami)

# --- Detect git repo (shared by directory + git_part below)
in_repo=0
repo_root=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    in_repo=1
    repo_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
fi

# --- Directory
# In a repo: just the repo root name. Otherwise: full path, with $HOME → ~
if [ "$in_repo" = "1" ] && [ -n "$repo_root" ]; then
    short_dir=$(basename "$repo_root")
else
    home=$(cd ~ && pwd)
    if [ "$cwd" = "$home" ]; then
        short_dir="~"
    elif [ "${cwd#$home/}" != "$cwd" ]; then
        short_dir="~/${cwd#$home/}"
    else
        short_dir="$cwd"
    fi
fi

# --- Git branch + status
git_part=""
if [ "$in_repo" = "1" ]; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

    staged=$(git -C "$cwd" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    modified=$(git -C "$cwd" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    ahead=0; behind=0
    upstream=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref '@{u}' 2>/dev/null)
    if [ -n "$upstream" ]; then
        ahead=$(git -C "$cwd" --no-optional-locks rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
        behind=$(git -C "$cwd" --no-optional-locks rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
    fi

    status_str=""
    [ "$staged" -gt 0 ]    && status_str="${status_str}${GREEN}+${staged} ${RST}"
    [ "$modified" -gt 0 ]  && status_str="${status_str}${YELLOW}*${modified} ${RST}"
    [ "$untracked" -gt 0 ] && status_str="${status_str}${WHITE}?${untracked} ${RST}"
    [ "$ahead" -gt 0 ]     && status_str="${status_str}${BOLD_RED}⇡${ahead} ${RST}"
    [ "$behind" -gt 0 ]    && status_str="${status_str}${BOLD_RED}⇣${behind} ${RST}"

    branch_seg="${RED} $(printf '\xee\x82\xa0') ${branch}${RST}"
    git_part="${branch_seg}${status_str:+ ${status_str}}"
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

# --- Assemble
printf '%s%s%s' "$BRIGHT_WHITE" "$user" "$RST"
printf '%s in %s' "$RED" "$RST"
printf '%s%s%s' "$BRIGHT_WHITE_ITALIC" "$short_dir" "$RST"
[ -n "$git_part" ] && printf ' %s' "$git_part"
printf '\n'

# Bottom line: model + usage sections, joined by " | "
printf '%s[%s%s' "$DIM" "$model" "$RST"

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
    local label=$1 value=$2 paren=$3
    emit_sep
    printf '%s%s:%s %s%s%%%s' "$BOLD" "$label" "$RST" "$BLUE" "$value" "$RST"
    [ -n "$paren" ] && printf ' %s(%s)%s' "$DIM" "$paren" "$RST"
}

if [ -n "$used_pct" ]; then
    ctx_int=$(printf '%.0f' "$used_pct")
    emit_section "ctx" "$ctx_int" ""
fi
if [ -n "$five_h_pct" ]; then
    five_int=$(printf '%.0f' "$five_h_pct")
    paren=""
    [ -n "$five_h_reset" ] && paren=$(fmt_reset "$five_h_reset")
    emit_section "5h" "$five_int" "$paren"
fi
if [ -n "$week_pct" ]; then
    week_int=$(printf '%.0f' "$week_pct")
    paren=""
    [ -n "$week_reset" ] && paren=$(fmt_reset "$week_reset")
    emit_section "7d" "$week_int" "$paren"
fi

printf '%s]%s' "$DIM" "$RST"

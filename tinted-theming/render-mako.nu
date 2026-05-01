#!/usr/bin/env nu

# Render mako colors.config from the active tinty scheme yaml.

let schemes_dir = $"($env.HOME)/.local/share/tinted-theming/tinty/repos/schemes/base16"
let short = (^tinty current | str trim | str replace -r '^base16-' '')
let scheme_file = $"($schemes_dir)/($short).yaml"

if not ($scheme_file | path exists) {
  print -e $"render-mako: scheme file not found: ($scheme_file)"
  exit 1
}

let p = (open $scheme_file).palette
let dst = $"($env.HOME)/.config/mako/colors.config"
mkdir ($dst | path dirname)

[
  $"background-color=($p.base00)"
  $"text-color=($p.base05)"
  $"border-color=($p.base0D)"
  ""
  "[urgency=low]"
  $"background-color=($p.base00)"
  $"text-color=($p.base0A)"
  $"border-color=($p.base0D)"
  ""
  "[urgency=high]"
  $"background-color=($p.base00)"
  $"text-color=($p.base08)"
  $"border-color=($p.base0D)"
] | str join (char nl) | save -f $dst

try { ^makoctl reload err> /dev/null }

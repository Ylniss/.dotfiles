#!/usr/bin/env nu

# Render mako colors.config from the active tinty scheme.

let opacity = 0.75

let schemes_dir = $"($env.HOME)/.local/share/tinted-theming/tinty/repos/schemes/base16"
let scheme_short = (^tinty current | str trim | str replace -r '^base16-' '')
let scheme_file = $"($schemes_dir)/($scheme_short).yaml"

if not ($scheme_file | path exists) {
  print -e $"render-mako: scheme file not found: ($scheme_file)"
  exit 1
}

let palette = (open $scheme_file).palette
let background_alpha_hex = (^printf '%02x' ($opacity * 255 | math round | into int))
let translucent_background = $"($palette.base00)($background_alpha_hex)"

let output_path = $"($env.HOME)/.config/mako/colors.config"
mkdir ($output_path | path dirname)

[
  $"background-color=($translucent_background)"
  $"text-color=($palette.base05)"
  $"border-color=($palette.base0D)"
  ""
  "[urgency=low]"
  $"background-color=($translucent_background)"
  $"text-color=($palette.base0A)"
  $"border-color=($palette.base0D)"
  ""
  "[urgency=high]"
  $"background-color=($translucent_background)"
  $"text-color=($palette.base08)"
  $"border-color=($palette.base0D)"
] | str join (char nl) | save -f $output_path

try { ^makoctl reload err> /dev/null }

#!/usr/bin/env nu

# Render fuzzel colors.ini from the active tinty scheme.

let opacity = 0.75

let schemes_dir = $"($env.HOME)/.local/share/tinted-theming/tinty/repos/schemes/base16"
let scheme_short_name = (^tinty current | str trim | str replace -r '^base16-' '')
let scheme_file = $"($schemes_dir)/($scheme_short_name).yaml"

if not ($scheme_file | path exists) {
  print -e $"render-fuzzel: scheme file not found: ($scheme_file)"
  exit 1
}

let palette = (open $scheme_file).palette
let background_alpha_hex = (^printf '%02x' ($opacity * 255 | math round | into int))
let opaque_alpha_hex = "ff"

def hex_with_alpha [color: string, alpha_hex: string] {
  ($color | str replace '#' '') + $alpha_hex
}

let output_path = $"($env.HOME)/.config/fuzzel/colors.ini"
mkdir ($output_path | path dirname)

[
  "[colors]"
  $"background=(hex_with_alpha $palette.base00 $background_alpha_hex)"
  $"text=(hex_with_alpha $palette.base05 $opaque_alpha_hex)"
  $"match=(hex_with_alpha $palette.base0D $opaque_alpha_hex)"
  $"selection=(hex_with_alpha $palette.base03 $opaque_alpha_hex)"
  $"selection-text=(hex_with_alpha $palette.base06 $opaque_alpha_hex)"
  $"selection-match=(hex_with_alpha $palette.base0D $opaque_alpha_hex)"
  $"border=(hex_with_alpha $palette.base05 $opaque_alpha_hex)"
] | str join (char nl) | save -f $output_path

#!/usr/bin/env nu

# Render fuzzel colors.ini from the active tinty scheme.

use _lib.nu *

let opacity = 0.75
let palette = (palette)
let bg_alpha = (alpha-hex $opacity)
let opaque = "ff"

def with_alpha [color: string, alpha_hex: string] {
  ($color | str replace '#' '') + $alpha_hex
}

let output_path = $"($env.HOME)/.config/fuzzel/colors.ini"
mkdir ($output_path | path dirname)

[
  "[colors]"
  $"background=(with_alpha $palette.base00 $bg_alpha)"
  $"text=(with_alpha $palette.base05 $opaque)"
  $"match=(with_alpha $palette.base0D $opaque)"
  $"selection=(with_alpha $palette.base03 $opaque)"
  $"selection-text=(with_alpha $palette.base06 $opaque)"
  $"selection-match=(with_alpha $palette.base0D $opaque)"
  $"border=(with_alpha $palette.base05 $opaque)"
] | str join (char nl) | save -f $output_path

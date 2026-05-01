#!/usr/bin/env nu

# Render mako colors.config from the active tinty scheme.

use _lib.nu *

let opacity = 0.75
let palette = (palette)
let translucent_bg = $"($palette.base00)(alpha-hex $opacity)"

let output_path = $"($env.HOME)/.config/mako/colors.config"
mkdir ($output_path | path dirname)

[
  $"background-color=($translucent_bg)"
  $"text-color=($palette.base05)"
  $"border-color=($palette.base0D)"
  ""
  "[urgency=low]"
  $"background-color=($translucent_bg)"
  $"text-color=($palette.base0A)"
  $"border-color=($palette.base0D)"
  ""
  "[urgency=high]"
  $"background-color=($translucent_bg)"
  $"text-color=($palette.base08)"
  $"border-color=($palette.base0D)"
] | str join (char nl) | save -f $output_path

try { ^makoctl reload err> /dev/null }

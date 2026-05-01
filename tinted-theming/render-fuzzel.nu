#!/usr/bin/env nu

# Render fuzzel colors.ini from the active tinty scheme yaml.

let schemes_dir = $"($env.HOME)/.local/share/tinted-theming/tinty/repos/schemes/base16"
let short = (^tinty current | str trim | str replace -r '^base16-' '')
let scheme_file = $"($schemes_dir)/($short).yaml"

if not ($scheme_file | path exists) {
  print -e $"render-fuzzel: scheme file not found: ($scheme_file)"
  exit 1
}

let p = (open $scheme_file).palette

def alpha [c: string] {
  let s = ($c | str replace '#' '')
  $"($s)ff"
}

let dst = $"($env.HOME)/.config/fuzzel/colors.ini"
mkdir ($dst | path dirname)

[
  "[colors]"
  $"background=(alpha $p.base00)"
  $"text=(alpha $p.base05)"
  $"match=(alpha $p.base0D)"
  $"selection=(alpha $p.base03)"
  $"selection-text=(alpha $p.base06)"
  $"selection-match=(alpha $p.base0D)"
  $"border=(alpha $p.base05)"
] | str join (char nl) | save -f $dst

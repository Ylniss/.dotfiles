#!/usr/bin/env nu

# Updates background opacity (0.0–1.0) across wezterm, waybar, foot, fuzzel, mako.
# Re-renders fuzzel/mako outputs and signals foot/waybar to reload.
#
# Usage: nu set-opacity.nu 0.85

def main [opacity: float] {
  if $opacity < 0.0 or $opacity > 1.0 {
    error make { msg: $"opacity must be 0.0–1.0, got ($opacity)" }
  }

  let dotfiles_dir = $"($env.HOME)/stuff/repo/.dotfiles"

  let replacements = [
    { path: $"($dotfiles_dir)/wezterm/wezterm.lua",             pattern: 'window_background_opacity\s*=\s*[0-9.]+',   replacement: $"window_background_opacity = ($opacity)" }
    { path: $"($dotfiles_dir)/waybar/style.css",                pattern: 'alpha\(@(base[0-9a-fA-F]{2}),\s*[0-9.]+\)', replacement: ('alpha(@${1}, ' + ($opacity | into string) + ')') }
    { path: $"($dotfiles_dir)/foot/foot.ini",                   pattern: '(?m)^alpha\s*=\s*[0-9.]+',                  replacement: $"alpha=($opacity)" }
    { path: $"($dotfiles_dir)/tinted-theming/render-fuzzel.nu", pattern: 'let opacity\s*=\s*[0-9.]+',                 replacement: $"let opacity = ($opacity)" }
    { path: $"($dotfiles_dir)/tinted-theming/render-mako.nu",   pattern: 'let opacity\s*=\s*[0-9.]+',                 replacement: $"let opacity = ($opacity)" }
  ]

  for replacement in $replacements {
    let original_text = (open --raw $replacement.path)
    let updated_text = ($original_text | str replace -ar $replacement.pattern $replacement.replacement)
    if $original_text == $updated_text {
      print -e $"warning: no match in ($replacement.path)"
    } else {
      $updated_text | save -f $replacement.path
      print $"updated ($replacement.path)"
    }
  }

  ^nu $"($dotfiles_dir)/tinted-theming/render-fuzzel.nu"
  ^nu $"($dotfiles_dir)/tinted-theming/render-mako.nu"

  try { ^pkill -USR1 foot err> /dev/null }
  try { ^pkill -USR2 waybar err> /dev/null }

  print "done."
}

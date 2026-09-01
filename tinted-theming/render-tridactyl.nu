#!/usr/bin/env nu

# Render the tridactyl theme from the active tinty scheme.
# tinted-tridactyl's pre-rendered themes lag the schemes repo, so we vendor its
# template (tridactyl-theme.css.tmpl) and fill it here instead.

use _lib.nu *

let palette = (palette)

let template_path = $"($env.HOME)/stuff/repo/.dotfiles/tinted-theming/tridactyl-theme.css.tmpl"
let output_path = $"($env.HOME)/.config/tridactyl/themes/colors.css"
mkdir ($output_path | path dirname)

$palette
| columns
| reduce --fold (open --raw $template_path) {|key, css|
    $css | str replace -a $"{{($key)-hex}}" ($palette | get $key | str replace '#' '')
  }
| save -f $output_path

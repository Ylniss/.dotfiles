# tinted-theming

base16 theme system: tinty config + render scripts for tools without upstream pre-rendered files.

`render-tridactyl.nu` is a variant: upstream `tinted-tridactyl` ships a template, but its
pre-rendered themes lag the schemes repo. Building in the tinty clone makes it dirty and blocks
`tinty update`, so the template is vendored here as `tridactyl-theme.css.tmpl`.

## Opacity

Each tool stores opacity in its own format (lua float, CSS `alpha()`, foot.ini `alpha=`, hex alpha byte). To change globally:

    nu tinted-theming/set-opacity.nu 0.85

Updates `wezterm/wezterm.lua`, `waybar/style.css`, `foot/foot.ini`, `tinted-theming/render-{fuzzel,mako}.nu`. Re-renders fuzzel/mako outputs and signals foot/waybar to reload. Wezterm picks up its lua change automatically.

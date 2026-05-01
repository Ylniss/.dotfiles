# tinted-theming

base16 theme system: tinty config + render scripts for tools without upstream pre-rendered files.

## Opacity

Each tool stores opacity in its own format (lua float, CSS `alpha()`, foot.ini `alpha=`, hex alpha byte). To change globally:

    nu tinted-theming/set-opacity.nu 0.85

Updates `wezterm/wezterm.lua`, `waybar/style.css`, `foot/foot.ini`, `qutebrowser/config.py`, `tinted-theming/render-{fuzzel,mako}.nu`. Re-renders fuzzel/mako outputs and signals foot/waybar/qutebrowser to reload. Wezterm picks up its lua change automatically. Note: qutebrowser's `c.window.transparent` only applies to windows opened after it's set, so a full qutebrowser restart is needed when first enabling it (subsequent opacity tweaks live-reload via `:config-source`).

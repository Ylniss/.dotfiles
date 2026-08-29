# Neovim Config

Personal config for config/text file editing. Namespace: `ylniss`.

## Layout

- Filetype indentation lives in `tabs.lua`, not in plugin configs.

## Plugin Specs

Each file returns a lazy.nvim spec with this comment header:
```lua
-- ========================================================
-- PluginName
-- short one line description
-- ========================================================
return { ... }
```

Every plugin needs a lazy trigger unless immediately visible (colorscheme, statusline, dashboard).

## Keybindings (remap.lua)

- **Every mapping must have `desc`** (for which-key).
- **No top-level `require()` of a lazy plugin in remap.lua** — it forces startup loading. Plugin keymaps go in the plugin spec's `config`.

## LSP (plugins/lsp.lua)

- **stylua LSP disabled**: used only as formatter via conform. Disabled with `vim.lsp.enable("stylua", false)`.
- **Platform guards**: mason auto-install is off on NixOS (`uname.version:match("NixOS")`) and Android (`fs_stat("~/storage/dcim/camera")`). Keep both when changing mason setup.

## Gotchas

- **Nushell as default shell**: `vim.o.shell = "nu"` with custom `shellpipe`/`shellredir`. Shell commands must use Nushell piping (`| save %s`).
- **`Z`/`X` remapped**: `Z` = line start, `X` = line end.
- **Reversed paste**: `p` and `P` swapped.
- **Error handling**: `pcall()` for commands that may fail (e.g. `:wq` on unnamed buffers).
- **Format toggle**: `vim.g.disable_autoformat` / `vim.b[bufnr].disable_autoformat` control conform.nvim format-on-save.

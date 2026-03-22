# Neovim Config

Personal config for config/text file editing. Namespace: `ylniss`.

## Layout

- Core settings → `lua/ylniss/`. Plugin specs → `lua/ylniss/plugins/`.
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
- **No top-level `require()` in remap.lua** — forces startup loading. Plugin keymaps go in the plugin spec's `config`.

### Leader Prefixes
| Prefix | Category |
|--------|----------|
| `<leader>e` | explore |
| `<leader>g` | git |
| `<leader>s` | search |

## LSP (plugins/lsp.lua)

- **stylua LSP disabled**: used only as formatter via conform. Disabled with `vim.lsp.enable("stylua", false)`.
- **Platform guards**: mason auto-install disabled on NixOS (`uname.version:match("NixOS")`) and Android (`fs_stat("~/storage/dcim/camera")`). Preserve these when modifying mason setup.

## Gotchas

- **Nushell as default shell**: `vim.o.shell = "nu"` with custom `shellpipe`/`shellredir`. Shell commands must use Nushell piping (`| save %s`).
- **HJKL heavily remapped**: `H`/`L` = word, `J`/`K` = paragraph, `Z`/`X` = line start/end. NOT standard vim motions.
- **Reversed paste**: `p` and `P` swapped.
- **Error handling**: `pcall()` for commands that may fail (e.g., `:wq` on unnamed buffers). Check `vim.v.shell_error` after `vim.fn.system()`.
- **Git root detection**: NeoTree and fzf-lua resolve git root first. Follow `find_git_root()` in `plugins/fzf-lua.lua`.
- **Format toggle**: `vim.g.disable_autoformat` / `vim.b[bufnr].disable_autoformat` control conform.nvim format-on-save.

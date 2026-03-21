# Neovim Config

Personal Neovim configuration for config/text file editing. Namespace: `ylniss`.

## Project Structure

```
init.lua                    → requires "ylniss"
lua/ylniss/
  init.lua                  → loads set, lazy.nvim bootstrap, remap, tabs (in order)
  set.lua                   → vim options, autocommands, shell config
  remap.lua                 → keybindings not tied to specific plugins
  tabs.lua                  → per-filetype indentation
  plugins/                  → one file per plugin (lazy.nvim auto-discovers)
    alpha.lua               → dashboard
    blink-cmp.lua           → autocompletion
    conform.lua             → formatter
    fzf-lua.lua             → fuzzy finder
    fugitive.lua            → git client
    gitsigns.lua            → git gutter signs
    indent-blankline.lua    → indentation guides
    kanagawa.lua            → colorscheme + lualine + highlights
    lazydev.lua             → Neovim Lua development
    lsp.lua                 → LSP + mason
    neo-tree.lua            → file explorer
    smart-splits.lua        → window navigation
    surround.lua            → surround pairs
    treesitter.lua          → syntax highlighting
    which-key.lua           → keybinding hints
    autopairs.lua           → auto-close brackets
```

- **Core settings** go in `lua/ylniss/`. **Plugin specs + config** go in `lua/ylniss/plugins/`.
- Each plugin file returns a lazy.nvim spec table (or list of tables).
- Indentation per filetype is in `tabs.lua`, not scattered across plugin configs.

## Plugin Specs (lua/ylniss/plugins/)

Each file returns a lazy.nvim spec. Every file starts with a comment header:
```lua
-- ========================================================
-- PluginName
-- short one line description
-- ========================================================
return { ... }
```

Patterns used:
- **Simple**: `return { "author/plugin", opts = {} }` — uses plugin defaults
- **With config**: `return { "author/plugin", config = function() ... end }` — custom setup
- **Lazy triggers**: `event`, `cmd`, `keys`, `ft` — defer loading until needed
- **Multi-spec**: return a list `{ { spec1 }, { spec2 } }` for related plugins (e.g., kanagawa + lualine)

Every plugin should have a lazy trigger unless it must be visible immediately (colorscheme, statusline, dashboard).

## Keybindings (remap.lua)

- Always use `vim.keymap.set(mode, lhs, rhs, { desc = "..." })` — never legacy `map()`.
- **Every mapping must have a `desc` field** (for which-key).
- Sections separated by comment banners: `-- ====== Section Name ======`.
- Complex logic extracted into local functions above the mapping.
- Use `{ remap = true }` only when chaining to built-in mappings (e.g., Neovim's built-in `gcc`).
- Use `{ expr = true }` for count-aware mappings (e.g., `gj`/`gk` with count).
- **Do not `require()` plugins at the top level of remap.lua** — this forces them to load at startup. Plugin-specific keymaps go in the plugin spec's `config` function.

Leader groups registered via `which-key.add()` at the bottom of the file.

### Leader Prefixes
| Prefix | Category |
|--------|----------|
| `<leader>c` | code |
| `<leader>e` | explore |
| `<leader>g` | git |
| `<leader>s` | search |
| `<leader>d` | debug |

## LSP (plugins/lsp.lua)

- Servers: `dockerls`, `jsonls`, `yamlls`, `taplo`, `terraformls`, `lua_ls`.
- `LspAttach` autocmd defines buffer-local LSP keymaps using a local helper.
- LSP keybinding descriptions prefixed with `"lsp: "`.
- LSP actions (`rename`, `code_action`, `hover`) use built-in `vim.lsp.buf.*`.
- LSP navigation (`definitions`, `references`, `implementations`, `typedefs`) uses fzf-lua pickers.
- Capabilities auto-patched by `blink.cmp`.
- **stylua LSP disabled**: stylua is used only as a formatter (via conform), not as an LSP. The auto-detected `stylua` LSP config is explicitly disabled with `vim.lsp.enable("stylua", false)`.
- **Platform guards**: auto-install disabled on NixOS (`uname.version:match("NixOS")`) and Android (`fs_stat("~/storage/dcim/camera")`). Keep these guards when modifying mason setup.

## Autocommands

- Use `vim.api.nvim_create_augroup("GroupName", { clear = true })` for groups.
- Use `vim.api.nvim_create_autocmd(event, { callback, group, pattern })`.
- FileType-specific settings use the `FileType` event with `vim.bo.*` (buffer options).

## Theme (plugins/kanagawa.lua)

- Kanagawa theme with **transparent backgrounds everywhere** (`bg = "none"`).
- Kanagawa `overrides` function handles plugin-specific theming (Lazy, Mason).
- Lualine theme derived from `auto` with transparent `normal.c` background.
- All custom highlights (git signs, cursor, cursorline) set in kanagawa's `config`.

## Gotchas

- **Nushell as default shell**: `vim.o.shell = "nu"` with custom `shellpipe`/`shellredir` syntax. Shell commands in the config must work with Nushell piping (`| save %s`).
- **HJKL heavily remapped**: `H`/`L` = word movement, `J`/`K` = paragraph movement, `Z`/`X` = line start/end. These are NOT standard vim motions.
- **Reversed paste**: `p` and `P` are swapped.
- **Error handling**: Use `pcall()` for commands that may fail (e.g., `:wq` on unnamed buffers). Check `vim.v.shell_error` after `vim.fn.system()` calls.
- **Git root detection**: NeoTree and fzf-lua resolve git root before operating. When adding similar features, follow the `find_git_root()` pattern in `plugins/fzf-lua.lua`.
- **Format toggle**: `vim.g.disable_autoformat` / `vim.b[bufnr].disable_autoformat` control conform.nvim format-on-save.

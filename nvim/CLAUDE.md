# Neovim Config

Personal Neovim configuration for config/text file editing. Namespace: `ylniss`.

## Project Structure

```
init.lua                    → requires "ylniss"
lua/ylniss/
  init.lua                  → loads set, plugins, remap, tabs (in order)
  set.lua                   → vim options, autocommands, shell config
  plugins.lua               → lazy.nvim bootstrap + all plugin specs
  remap.lua                 → all keybindings
  tabs.lua                  → per-filetype indentation
after/plugin/               → plugin-specific setup (runs after plugins load)
  lsp/                      → LSP-related setup (mason)
```

- **Core settings** go in `lua/ylniss/`. **Plugin configuration** goes in `after/plugin/`.
- One file per plugin in `after/plugin/`. LSP-related config lives in `after/plugin/lsp/`.
- Indentation per filetype is in `tabs.lua`, not scattered across plugin configs.

## Plugin Specs (plugins.lua)

All plugins defined in a single `require("lazy").setup({...})` call. Patterns used:

- **Simple**: `"author/plugin"` — no config needed, or configured in `after/plugin/`
- **With deps**: `{ "author/plugin", dependencies = { ... } }`
- **With defaults**: `{ "author/plugin", opts = {} }` — uses plugin defaults
- **Lazy-loaded**: add `event = "VeryLazy"` or `event = "InsertEnter"` etc.

Plugin setup/customization code belongs in `after/plugin/`, not inline in the spec.

## Keybindings (remap.lua)

- Always use `vim.keymap.set(mode, lhs, rhs, { desc = "..." })` — never legacy `map()`.
- **Every mapping must have a `desc` field** (for which-key).
- Sections separated by comment banners: `-- ====== Section Name ======`.
- Complex logic extracted into local functions above the mapping.
- Use `{ remap = true }` only when chaining to built-in mappings (e.g., Neovim's built-in `gcc`).
- Use `{ expr = true }` for count-aware mappings (e.g., `gj`/`gk` with count).

Leader groups registered via `which-key.add()` at the bottom of the file.

### Leader Prefixes
| Prefix | Category |
|--------|----------|
| `<leader>c` | code |
| `<leader>e` | explore |
| `<leader>g` | git |
| `<leader>s` | search |
| `<leader>d` | debug |

## LSP (after/plugin/lsp/mason.lua)

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

## Theme (after/plugin/colors.lua)

- Kanagawa theme with **transparent backgrounds everywhere** (`bg = "none"`).
- Kanagawa `overrides` function handles plugin-specific theming (Lazy, Mason).
- Lualine theme derived from `auto` with transparent `normal.c` background.
- Treesitter setup also lives in this file.

## Gotchas

- **Nushell as default shell**: `vim.o.shell = "nu"` with custom `shellpipe`/`shellredir` syntax. Shell commands in the config must work with Nushell piping (`| save %s`).
- **HJKL heavily remapped**: `H`/`L` = word movement, `J`/`K` = paragraph movement, `Z`/`X` = line start/end. These are NOT standard vim motions.
- **Reversed paste**: `p` and `P` are swapped.
- **Error handling**: Use `pcall()` for commands that may fail (e.g., `:wq` on unnamed buffers). Check `vim.v.shell_error` after `vim.fn.system()` calls.
- **Git root detection**: Both NeoTree and fzf-lua resolve git root before operating. When adding similar features, follow the `find_git_root()` pattern in `fzf-lua.lua`.
- **Format toggle**: `vim.g.disable_autoformat` / `vim.b[bufnr].disable_autoformat` control conform.nvim format-on-save.

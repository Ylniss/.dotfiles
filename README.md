# .dotfiles

Nushell + Wezterm + Neovim config for Windows and NixOS. Bootstrap with `install_dotfiles.nu`.

## Git (Nushell)

| Command | Action |
|---------|--------|
| `gits` | git status |
| `gitd` | diff unstaged + staged |
| `gita [path]` | git add (defaults to `.`) |
| `gitc [msg]` | git commit |
| `gitp [branch]` | git push to origin |
| `gitbch <branch>` | create + checkout branch |
| `gitmrg <branch>` | merge remote branch |
| `gitl` | git log as table |
| `gitl -g` | git log as graph |
| `giti [name] [-g]` | init repo, `-g` creates on GitHub |
| `gitwta <branch>` | add worktree, cd into it, open layout-dev |
| `gitwtf <path>` | push branch, merge into base, remove worktree |

## Wezterm

Pane nav (`Ctrl+HJKL`) is shared with Neovim splits via smart-splits.

### Panes

| Key | Action |
|-----|--------|
| `Ctrl+H/J/K/L` | Navigate panes |
| `Meta+H/J/K/L` | Resize panes |
| `Ctrl+Shift+V` | Split horizontal |
| `Ctrl+Shift+H` | Split vertical |
| `Ctrl+Shift+T` | Small bottom pane |
| `Ctrl+Shift+Q` | Close pane |

### Tabs

| Key | Action |
|-----|--------|
| `Ctrl+T` | New tab |
| `Ctrl+Shift+W` | Close tab |
| `Ctrl+1-9` | Switch to tab |

### Other

`layout-dev` — 3-pane layout: left 60%, right 40% (split 80/20)

| Key | Action |
|-----|--------|
| `Ctrl+E / Ctrl+Y` | Scroll up / down |
| `Shift+Alt+L` | Launcher |

## Neovim

> **HJKL is remapped.** `H`/`L` = word, `J`/`K` = paragraph, `Z`/`X` = line start/end.

### Navigation

| Key | Action |
|-----|--------|
| `H` / `L` | Word left / right |
| `J` / `K` | Paragraph down / up |
| `Z` / `X` | Line start / end |
| `Ctrl+B` | Matching bracket |
| `Ctrl+D` / `Ctrl+U` | Half-page down / up (centered) |
| `]` / `[` | Next / prev buffer |
| `<leader>n` | Previous file |

### File & Window

| Key | Action |
|-----|--------|
| `Ctrl+S` | Save file |
| `Ctrl+Shift+S` | Save all |
| `<leader>q` | Save and close |
| `<leader>Q` | Close without saving |
| `<leader>e` | Toggle NeoTree |
| `<leader>v` / `<leader>h` | Vertical / horizontal split |
| `Ctrl+H/J/K/L` | Navigate windows |
| `Alt+H/J/K/L` | Resize windows |
| `yf` | Yank whole file |

### Git

| Key | Action |
|-----|--------|
| `<leader>gs` | Git status (right split) |
| `<leader>gr` | Toggle show deleted lines |
| `=` | Toggle inline diff (in `:Git` status) |
| `dh` | Horizontal diff split (in `:Git` status) |

### Search (fzf-lua)

| Key | Action |
|-----|--------|
| `<leader>sf` | Search all files |
| `<leader>sg` | Grep on git root |
| `<leader>?` | Recent files |
| `<leader>/` | Search current buffer |
| `<leader>sd` | Search diagnostics |

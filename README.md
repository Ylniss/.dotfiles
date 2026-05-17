Nushell + Wezterm + Neovim config for Windows and Linux. Bootstrap with `scripts/install_dotfiles.nu`.

# Git (Nushell)

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

# Robes & Steel (Nushell)

| Command | Action |
|---------|--------|
| `rns imgprocess <file>` | Process sprite image into silhouette via `process_image.cs` |

# Wezterm

Pane nav (`Ctrl+HJKL`) is shared with Neovim splits via smart-splits.

## Panes

| Key | Action |
|-----|--------|
| `Ctrl+H/J/K/L` | Navigate panes |
| `Meta+H/J/K/L` | Resize panes |
| `Ctrl+Shift+V` | Split horizontal |
| `Ctrl+Shift+H` | Split vertical |
| `Ctrl+Shift+T` | Small bottom pane |
| `Ctrl+Shift+Q` | Close pane |

## Tabs

| Key | Action |
|-----|--------|
| `Ctrl+T` | New tab |
| `Ctrl+Shift+W` | Close tab |
| `Ctrl+1-9` | Switch to tab |

## Other

`layout-dev` — 3-pane layout: left 60%, right 40% (split 80/20)

| Key | Action |
|-----|--------|
| `Ctrl+E / Ctrl+Y` | Scroll up / down |
| `Shift+Alt+L` | Launcher |

# Yazi

## Dependencies

**Windows**

```
winget install --scope machine ImageMagick.ImageMagick sharkdp.bat Inkscape.Inkscape JesseDuffield.lazygit
scoop install --global ffmpeg poppler resvg
```

**Linux (apt)**

```
sudo apt install ffmpeg imagemagick poppler-utils resvg bat inkscape lazygit
```

**Linux (pacman)**

```
sudo pacman -S ffmpeg imagemagick poppler resvg bat inkscape lazygit
```

On Debian/Ubuntu, `bat` may be installed as `batcat`; symlink it with `sudo ln -s /usr/bin/batcat /usr/local/bin/bat` if so.

## Keys

| Key | Action |
|-----|--------|
| `t` | New tab at hovered directory |
| `J` / `K` | Half page down / up |
| `g s/n/r/a/m//` | Jump to stuff / knowtes / repo / games / movies / root |
| `g i` | Open lazygit |

# Neovim

## Navigation

| Key | Action |
|-----|--------|
| `H` / `L` | Word left / right |
| `J` / `K` | Paragraph down / up |
| `Z` / `X` | Line start / end |
| `Ctrl+B` | Matching bracket |
| `Ctrl+D` / `Ctrl+U` | Half-page down / up (centered) |
| `]` / `[` | Next / prev buffer |
| `<leader>n` | Previous file |

## File & Window

| Key | Action |
|-----|--------|
| `<leader>e` | Open Yazi at current file |
| `<leader>E` | Open Yazi at cwd |
| `<leader>v` / `<leader>h` | Vertical / horizontal split |
| `Ctrl+H/J/K/L` | Navigate windows |
| `Alt+H/J/K/L` | Resize windows |
| `yf` | Yank whole file |

## Git

| Key | Action |
|-----|--------|
| `<leader>gr` | Toggle show deleted lines |
| `<leader>gi` | Open lazygit |

## Search (fzf-lua)

| Key | Action |
|-----|--------|
| `<leader>sf` | Search all files |
| `<leader>sg` | Grep on git root |
| `<leader>?` | Recent files |
| `<leader>/` | Search current buffer |
| `<leader>sd` | Search diagnostics |
| `<leader>yd` | Yank diagnostic on current line to clipboard |

# Obsidian

## Neovim Integration

Uses [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim) — wikilink following, backlinks, completion for `[[...]]` and `#tags`. Loads on markdown files or `:Obsidian` commands. Picker: fzf-lua.

Buffer-local keys in vault notes:

| Key | Action |
|-----|--------|
| `gd` | Follow wikilink under cursor |
| `gb` | Show backlinks |
| `<leader>sf` | Fuzzy-find vault notes (overrides global fzf-lua files) |
| `<leader>sg` | Grep vault (overrides global fzf-lua grep) |
| `<leader>t` | Toggle checkbox |
| `[[` / `#` (insert) | Trigger link / tag completion |

Visual-mode markdown surround (any markdown file):

| Key | Action |
|-----|--------|
| `<leader>\`` | Surround selection with backticks |
| `<C-b>` | Bold (`**`) |
| `<C-i>` | Italic (`*`) |

Useful commands from any buffer:

| Command | Action |
|---------|--------|
| `:Obsidian new [title]` | Create a new note |

## Custom Dictionary

`Custom Dictionary.txt` is copied (not symlinked) — Obsidian rewrites it with a checksum and would reject a symlinked file.

To save new words from Obsidian into the repo:

1. Close Obsidian.
2. Run `nu scripts/sync_obsidian_dictionary.nu` — merges words from Obsidian and repo, writes to both.
3. Reopen Obsidian and commit the change.

# qutebrowser

## Video playback (mpv)

YouTube and other video links open in **mpv** instead of qutebrowser's web player — bypasses ads completely (yt-dlp grabs the raw stream, no JS, no DOM). Includes [SponsorBlock](https://sponsor.ajay.app/) for skipping in-video sponsor segments.

Auto-fetches YouTube auto-generated English captions via yt-dlp; subs are off by default — toggle with `v` in mpv.

### Dependencies

**Linux (pacman)**

```
sudo pacman -S mpv yt-dlp
```

### Keys

| Key | Action |
|-----|--------|
| `<Space>w` | Watch video — spawn mpv with current page URL |
| `<Space>gs` | Search via DuckDuckGo |
| `<Space>gh` | Open GitHub |
| `<Space>gy` | Open YouTube |
| `<Space>gr` | Open Reddit |
| `<Space>m` | Mute current tab |
| `<Space>p` | Pin current tab |

In mpv:

| Key | Action |
|-----|--------|
| `v` | Toggle subtitle visibility |
| `j` | Cycle subtitle tracks |
| `b` | Toggle SponsorBlock skipping |
| `q` | Quit mpv |

# Docker

Build the dotfiles image (Arch base + nushell, neovim, yazi, lazygit, Mason LSPs preinstalled):

```
docker build -t ghcr.io/ylniss/dotfiles:latest .
```

Push to GitHub Container Registry:

```
gh auth token | docker login ghcr.io -u ylniss --password-stdin
docker push ghcr.io/ylniss/dotfiles:latest
```

> **TODO:** move the build + push to GitHub Actions.

#!/usr/bin/env bash
# Installs dotfiles dependencies on Ubuntu via apt (prereqs) + Homebrew (tools).

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "error: do not run as root — Homebrew refuses. Run as a non-root sudo user." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential procps curl file git ca-certificates \
  xdg-utils unzip

if ! command -v brew >/dev/null 2>&1 && [[ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

brew_line='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
if ! grep -qF "$brew_line" "$HOME/.bashrc" 2>/dev/null; then
  echo "$brew_line" >> "$HOME/.bashrc"
fi

brew install \
  btop \
  nushell neovim yazi starship \
  bat ripgrep fd fzf \
  lazygit

#!/usr/bin/env bash
# Installs dotfiles dependencies on Arch via pacman.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "error: run as root (pacman requires root)" >&2
  exit 1
fi

pacman -Syu --noconfirm --needed \
  git openssh xdg-utils btop \
  nushell neovim yazi starship \
  bat ripgrep fd fzf jq libnotify \
  lazygit unzip \
  mpv yt-dlp

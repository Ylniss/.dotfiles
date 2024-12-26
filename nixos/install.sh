#!/usr/bin/env bash

################################################################################
# IMPORTANT: This script requires a ".ssh" folder with valid GitHub SSH keys
# in the same directory as the script. It will exit if the folder is missing.
#
# How to use:
# 1. Place your .ssh folder (with id_rsa, id_rsa.pub, etc.) alongside this script.
# 2. Make the script executable: chmod +x install.sh
# 3. Run the script: ./install.sh
################################################################################

REPO_URL="git@github.com:Ylniss/.dotfiles.git"
TARGET_DIR="~/stuff/repo" # Target directory for the repository

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Check for .ssh folder
echo -e "${GREEN}Checking for .ssh folder...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -d "$SCRIPT_DIR/.ssh" ]; then
  echo -e "${RED}ERROR: .ssh folder is missing. Place it in $SCRIPT_DIR and try again.${NC}"
  exit 1
fi

# Move .ssh folder
echo -e "${GREEN}Moving SSH keys...${NC}"
mv "$SCRIPT_DIR/.ssh" ~/ || { echo -e "${RED}Failed to move SSH keys.${NC}"; exit 1; }

# Start ssh-agent
echo -e "${GREEN}Starting SSH agent...${NC}"
eval "$(ssh-agent -s)"

# Create necessary directories
echo -e "${GREEN}Setting up directories...${NC}"
mkdir -p $TARGET_DIR
cd $TARGET_DIR || exit 1

# Ensure git is available and clone repository
echo -e "${GREEN}Cloning repository...${NC}"
nix-shell -p git --run "git clone $REPO_URL"

# Verify clone success
if [ ! -d ".dotfiles" ]; then
  echo -e "${RED}ERROR: Cloning failed or .dotfiles directory is missing.${NC}"
  exit 1
fi

# Rebuild NixOS
echo -e "${GREEN}Rebuilding NixOS configuration...${NC}"
sudo nixos-rebuild switch --flake $TARGET_DIR/.dotfiles/nixos

echo -e "${GREEN}Setup complete!${NC}"


{ config, pkgs, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/stuff/repo/.dotfiles";
in {
  home.stateVersion = "24.11";

  home.file = {
    ".config/nvim".source = "${dotfiles}/nvim";
    ".gitconfig".source = "${dotfiles}/.gitconfig";
    ".ideavimrc".source = "${dotfiles}/.ideavimrc";
    ".wezterm.lua".source = "${dotfiles}/.wezterm.lua";
    ".zshrc".source = "${dotfiles}/.zshrc";
    ".config/lf/lfrc".source = "${dotfiles}/lf/linux/lfrc";
    ".config/starship.toml".source = "${dotfiles}/starship.toml";
    ".config/nushell/config.nu".source = "${dotfiles}/nushell/config.nu";
    ".config/nushell/env.nu".source = "${dotfiles}/nushell/env.nu";
    ".config/nushell/scripts".source = "${dotfiles}/nushell/scripts";
    "/etc/nixos/configuration.nix".source = "${dotfiles}/nixos/configuration.nix";
    ".config/nixpkgs/home.nix".source = "${dotfiles}/nixos/home.nix";
  };
}

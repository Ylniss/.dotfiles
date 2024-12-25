{
  lib,
  pkgs,
  ...
}: {
  home.file = {
    # Setup symlinks to nvim config
    ".config/nvim".source = ../../../nvim;
    ".config/nvim".recursive = true;
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    extraConfig = lib.fileContents ../../../nvim/init.lua;
    extraPackages = with pkgs; [
      gcc
      xclip # copy paste out of nvim

      # LSPs
      lua-language-server
      typescript-language-server
      bash-language-server

      # Formatters
      prettierd
      eslint
      stylua # lua formatter
      gofumpt # go formatter
      alejandra # nix formatter
    ];
  };
}

{ lib, pkgs, ... } :

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    extraConfig = lib.fileContents ../../nvim/init.lua;
    extraPackages = with pkgs; [
      gcc
      xclip
      lua-language-server
      typescript-language-server
      bash-language-server
      prettierd
      eslint
      stylua
      gofumpt
    ];
  };	
}

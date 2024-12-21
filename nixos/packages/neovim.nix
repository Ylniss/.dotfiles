{ lib, ... } :

{
programs.neovim = {
  enable = true;
  extraConfig = lib.fileContents ../../nvim/init.lua;
};	
}

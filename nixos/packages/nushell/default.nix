{ lib, pkgs, config, ... } :

{
  programs.nushell = {
    enable = true;

    configFile.source = ./config.nu;
    envFile.source = ./env.nu;

    shellAliases = {
      repo = "cd ~/stuff/repo";
      dotfiles = "cd ~/stuff/repo/.dotfiles";
      downloads = "cd ~/Downloads/";
    };

    environmentVariables = {
      RIPGREP_CONFIG_PATH = "${config.home.homeDirectory}/.ripgreprc";
      EDITOR = "nvim";
      NU_LIB_DIRS = "${config.home.homeDirectory}/stuff/repo/.dotfiles/nixos/packages/nushell/scripts";
      NU_PLUGIN_DIRS = "${config.home.homeDirectory}/stuff/repo/.dotfiles/nixos/packages/nushell/plugins";
      PROMPT_INDICATOR_VI_INSERT = "";
      PROMPT_INDICATOR_VI_NORMAL = "";
    }; 

  };
}

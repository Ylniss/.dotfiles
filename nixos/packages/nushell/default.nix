{ pkgs, config, ... } :

{
  programs.nushell = {
    enable = true;

    configFile.source = ./config.nu;
    envFile.source = ./env.nu;

    shellAliases = {
      repo = "cd ~/stuff/repo";
      downloads = "cd ~/Downloads/";
    };

   environmentVariables = {
      RIPGREP_CONFIG_PATH = "${config.home.homeDirectory}/.ripgreprc";
      EDITOR = "nvim";
    }; 
  };
}

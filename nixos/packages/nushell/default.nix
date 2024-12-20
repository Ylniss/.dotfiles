{pkgs, ...} :

{
  programs.nushell = {
    enable = true;

    configFile.source = ./config.nu;
    envFile.source = ./env.nu;

    shellAliases = {
      repo = "cd ~/stuff/repo";
      downloads = "cd ~/Downloads/";
    };

  };
}

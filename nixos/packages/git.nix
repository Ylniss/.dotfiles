{ pkgs, ... } : 

{
  programs.git = {
    enable = true;
    userName = "Ylniss";
    userEmail = "zupqa0@gmail.com";
    delta.enable = true;
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
    };
  };
}

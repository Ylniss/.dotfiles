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

  # GitHub CLI tool
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
}

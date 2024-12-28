{pkgs, ...}: {
  home.packages = with pkgs; [
    git-credential-manager
  ];

  programs.git = {
    enable = true;
    userName = "Ylniss";
    userEmail = "zupqa0@gmail.com";
    delta.enable = true;
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      credential = {
        helper = "manager";
        "https://github.com".username = "Ylniss";
        credentialStore = "cache";
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

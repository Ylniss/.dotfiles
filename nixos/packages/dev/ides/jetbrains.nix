{pkgs, ...}: {
  home.packages = with pkgs; [
    jetbrains.rider
    jetbrains.goland
  ];

  home.file = {
    # Setup symlink for vim plugin options
    ".ideavimrc".source = ../../../../ideavim/.ideavimrc;
  };
}

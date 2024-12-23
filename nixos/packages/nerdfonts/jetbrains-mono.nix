{pkgs, ...}: {
  home.packages = with pkgs; [
    unstable.nerd-fonts.jetbrains-mono # works only on unstable nixos build
    #(nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];
}

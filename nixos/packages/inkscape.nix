{pkgs, ...}: {
  home.packages = with pkgs; [
    unstable.inkscape
  ];
}

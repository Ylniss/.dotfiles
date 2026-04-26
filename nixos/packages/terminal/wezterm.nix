{
  lib,
  inputs,
  pkgs,
  ...
}: {
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    package = inputs.wezterm.packages.${pkgs.system}.default;
    extraConfig = builtins.readFile ../../../wezterm/.wezterm.lua;
  };
}

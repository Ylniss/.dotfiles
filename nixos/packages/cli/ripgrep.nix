{
  lib,
  config,
  ...
}: {
  programs.ripgrep = {
    enable = true;
  };

  home.file = {
    ".ripgreprc".source = ../../../ripgrep/.ripgreprc;
  };

  # RIPGREP_CONFIG_PATH is set in nushell/default.nix
}

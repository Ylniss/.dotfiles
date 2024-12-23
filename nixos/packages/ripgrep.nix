{
  lib,
  config,
  ...
}: {
  programs.ripgrep = {
    enable = true;
  };

  home.file = {
    ".ripgreprc".source = ../../.ripgreprc;
  };
}

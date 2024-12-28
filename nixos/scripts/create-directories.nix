{
  config,
  lib,
  ...
}: {
  home.activation.createDirectories = lib.mkAfter ''
    mkdir -p ~/stuff/sec
    mkdir -p ~/stuff/bgdev
    mkdir -p ~/stuff/work
  '';
}

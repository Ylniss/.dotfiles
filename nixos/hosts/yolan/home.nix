{
  config,
  pkgs,
  lib,
  ...
}: {
  home.username = "yolan";
  home.homeDirectory = "/home/yolan";

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.activation.createDirectories = lib.mkAfter ''
    mkdir -p ~/stuff/sec
    mkdir -p ~/stuff/bgdev
    mkdir -p ~/stuff/work
  '';

  imports = [
    # Scripts
    ../../scripts/create-directories.nix
    ../../scripts/clone-git-repos.nix

    # Fonts
    ../../packages/fonts/jetbrains-mono.nix

    # Terminal
    ../../packages/terminal/nushell
    ../../packages/terminal/starship.nix
    ../../packages/terminal/wezterm.nix

    # CLI tools
    ../../packages/cli/neovim.nix
    ../../packages/cli/git.nix
    ../../packages/cli/fzf.nix
    ../../packages/cli/tree.nix
    ../../packages/cli/dust.nix
    ../../packages/cli/ripgrep.nix
    ../../packages/cli/fastfetch.nix
    ../../packages/cli/lf
    ../../packages/cli/gnumake.nix
    ../../packages/cli/psw.nix

    # Dev
    ../../packages/dev/dotnet9.nix
    ../../packages/dev/nodejs23.nix
    ../../packages/dev/go.nix

    # IDEs
    ../../packages/dev/ides/jetbrains.nix

    # Web
    ../../packages/web-browsers/brave.nix

    # Graphics
    ../../packages/graphics/inkscape.nix
    ../../packages/graphics/gimp.nix

    # Media
    ../../packages/media/spotify.nix
    ../../packages/media/vlc.nix

    # Communicators
    ../../packages/communicators/discord.nix

    # Windows compatibility
    ../../packages/utils/bottles.nix

    # VMWare
    ../../packages/utils/vmware.nix
  ];
}

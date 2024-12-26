{
  config,
  pkgs,
  ...
}: {
  home.username = "yolan";
  home.homeDirectory = "/home/yolan";

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  imports = [
    ../../packages/hyprland.nix

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

    # Dev
    ../../packages/dev/dotnet9.nix
    ../../packages/dev/nodejs23.nix

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

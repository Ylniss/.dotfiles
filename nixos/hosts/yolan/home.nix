{ config, pkgs, ... }:

{
  home.username = "yolan";
  home.homeDirectory = "/home/yolan";

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  home.file = {
    # Setup symlinks
    ".config/nvim".source = ../../../nvim;
    ".config/nvim".recursive = true;
    
    ".ideavimrc".source = ../../../.ideavimrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  imports = [
    ../../packages/nerdfonts/jetbrains-mono.nix

    # CLI
    ../../packages/nushell
    ../../packages/starship.nix
    ../../packages/wezterm.nix
    ../../packages/neovim.nix
    ../../packages/git.nix
    ../../packages/fzf.nix
    ../../packages/tree.nix
    ../../packages/dust.nix
    ../../packages/ripgrep.nix

    # Web
    ../../packages/brave.nix

    # Graphics
  ];
}

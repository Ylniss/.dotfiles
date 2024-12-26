{
  pkgs,
  config,
  ...
}: {
  xdg.configFile."lf/icons".source = ./icons;

  home.packages = with pkgs; [
    chafa
    ctpv
  ];

  xdg.configFile."ctpv/config".text = ''
    set forcechafa
    set chafasixel
  '';

  programs.lf = {
    enable = true;

    settings = {
      preview = true;
      hidden = true;
      drawbox = true;
      icons = true;
      ignorecase = true;
      scrolloff = 10;
      number = true;
      relativenumber = true;
      period = 1;
      sixel = true;
    };

    commands = {
      open = ''$$EDITOR $f'';
    };

    keybindings = {
      gr = "cd ~/stuff/repo";
      "g/" = "/";
      "." = "set hidden!";
    };

    previewer = {
      keybinding = "i";
      source = "${pkgs.ctpv}/bin/ctpv";
    };
    extraConfig = ''
      &${pkgs.ctpv}/bin/ctpv -s --polite $id
      cmd on-quit %${pkgs.ctpv}/bin/ctpv -e $id
      set cleaner ${pkgs.ctpv}/bin/ctpvclear
    '';
  };
}

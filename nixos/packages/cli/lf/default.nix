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
      mkdir = ''
        ''${{
          printf "Directory Name: "
          read ans
          mkdir $ans
        }}
      '';

      mkfile = ''
        ''${{
          printf "File Name: "
          read ans
          nvim $ans
        }}
      '';

      open = ''
        ''${{
          case $(file --mime-type "$f" -bL) in
            text/*|application/json) wezterm cli split-pane --right -- nvim "$f";;
            video/*|image/*/application/pdf) xdg-open "$f";;
            *) wezterm cli split-pane --right -- nvim "$f";;
          esac
        }}
      '';

      extract = ''
        ''${{
          set -f
          case $f in
              *.tar.bz|*.tar.bz2|*.tbz|*.tbz2) tar xjvf "$f";;
              *.tar.gz|*.tgz) tar xzvf "$f";;
              *.tar.xz|*.txz) tar xJvf "$f";;
              *.zip) ${pkgs.unzip}/bin/unzip "$f";;
              *.rar) ${pkgs.unrar}/bin/unrar x "$f";;
              *.7z) ${pkgs._7zz}/bin/7zz x "$f";;
              *.tar) tar xvf "$f";;
          esac
        }}
      '';

      archive = ''
        ''${{
          set -f
          mkdir "$f-zip"
          cp -r "$fx" "$f-zip"
          (cd "$f-zip/" && ${pkgs.zip}/bin/zip -r "$f.zip" .)
          mv "$f-zip/$f.zip" ./
          rm -rf "$f-zip/"
        }}
      '';

      quit-and-cd = ''
        &{{
          pwd > $LF_CD_FILE
          lf -remote "send $id quit"
        }}
      '';
    };

    keybindings = {
      "." = "set hidden!";

      gr = "cd ~/stuff/repo";
      "g/" = "cd /";

      J = "half-down";
      K = "half-up";

      xa = "archive";
      xe = "extract";

      A = "mkdir";
      a = "mkfile";
      q = "quit-and-cd";
      "<delete>" = "delete";
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

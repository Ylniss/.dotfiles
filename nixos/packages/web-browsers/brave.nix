{pkgs, ...}: {
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # ublock origin
      {id = "mnjggcdmjocbbbhaepdhchncahnbgone";} # yt sponsor block
      {id = "gebbhagfogifgggkldgodflihgfeippi";} # yt dislikes
    ];
    commandLineArgs = [
      "--disable-features=WebRtcAllowInputVolumeAdjustment"
    ];
  };
}

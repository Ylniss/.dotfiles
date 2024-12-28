{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    xclip # needed dependency for clipboard management
    inputs.psw.packages.${system}.psw
    inputs.psw.packages.${system}.clipclean
  ];
}

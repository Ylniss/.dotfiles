{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    inputs.psw.packages.${system}.psw
    inputs.psw.packages.${system}.clipclean
  ];
}

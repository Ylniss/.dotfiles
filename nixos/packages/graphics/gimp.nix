{pkgs, ...}: {
  home.packages = with pkgs; [
    gimp
    gimpPlugins.gmic
  ];
}
# todo: automate this
# after installation gimp will have wrong plugins path
# cd ~/.config/GIMP/2.10
# vi gimprc
# and replace line containing (plug-in-path "wrong/path") to:
# (plug-in-path "${gimp_dir}/plug-ins:/home/yolan/.nix-profile/lib/gimp/2.0/plug-ins")


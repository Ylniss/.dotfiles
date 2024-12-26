{pkgs, ...}: {
  # importh this module only when running on vmware
  home.packages = with pkgs; [
    open-vm-tools
  ];
}

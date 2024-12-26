{...}: {
  boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true; # turn on when on UEFI machine
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
}

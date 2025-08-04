{
  config,
  lib,
  ...
}: {
  boot.loader = {
    grub.enable = true;
    grub.version = 2;
    efi.canTouchEfiVariables = false;
  };

  boot.loader.systemd-boot.enable = false;
}

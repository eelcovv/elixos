{
  config,
  lib,
  ...
}: {
  boot.loader = {
    grub.enable = true;
    efi.canTouchEfiVariables = false;
  };

  boot.loader.systemd-boot.enable = false;
}

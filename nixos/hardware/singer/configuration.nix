{
  lib,
  config,
  ...
}: {
  imports = [
    ../modules/hardware/efi-boot-at-root.nix
  ];

  hardware.enableRedistributableFirmware = true;

  boot.initrd.luks.devices = {
    cryptroot.device = "/dev/disk/by-partlabel/luks-root";
    cryptswap.device = "/dev/disk/by-partlabel/luks-swap";
    crypthome.device = "/dev/disk/by-partlabel/luks-home";
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}

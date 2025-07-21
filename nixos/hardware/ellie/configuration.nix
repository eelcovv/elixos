{
  lib,
  config,
  ...
}: {
  imports = [
    ../../modules/hardware/efi-boot-at-root.nix
    ./hardware-configuration.nix
  ];

  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}

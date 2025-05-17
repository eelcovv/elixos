{ lib, config, ... }:

{
  imports = [
    ../modules/hardware/efi-boot.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = "x86_64-linux";
}

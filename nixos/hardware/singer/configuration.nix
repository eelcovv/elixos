{ lib, config, ... }: {
  imports = [
    ../../modules/hardware/efi-boot.nix
    ./hardware-configuration.nix
  ];

  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}


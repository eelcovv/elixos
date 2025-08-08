{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    ../../modules/hardware/efi-boot-at-root.nix
    ../../modules/hardware/gpu/nvidia.nix
    ../../modules/hardware/gpu/nvidia-wayland-env.nix
    ./hardware-configuration.nix
  ];

  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware.nvidia = {
    enable = true;
    driver = "proprietary";
  };
}

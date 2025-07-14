{ config, lib, pkgs, modulesPath, ... }:

{
    imports = [
    ../../modules/hardware/efi-boot.nix
    ../../modules/hardware/nvidea-wayland-env.nix
    ./hardware-configuration.nix
  ];

  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}


{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    ../../modules/hardware/efi-boot.nix
    ../../modules/hardware/efi-dualboot.nix
    ../../modules/hardware/gpu/nvidia.nix
    ../../modules/hardware/gpu/nvidia-wayland-env.nix
    ./hardware-configuration.nix
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.nvidia.enable = true;
  hardware.nvidia.useOpenDriver = false;

  specialisation = {
    nvidea.configuration = {
      system.nixos.tags = ["nvidea"];
      hardware.nvidia.prime = {
        sync.enable = true;
        nvidiaBusId = "PCI:0:1:0";
        amdgpuBusId = "PCI:0:7:0";
      };
    };

    on-the-go.configuration = {
      system.nixos.tags = ["on-the-go"];
      hardware.nvidia.prime = {
        sync.enable = lib.mkForce false;
        offload.enable = lib.mkForce true;
        offload.enableOffloadCmd = lib.mkForce true;
        nvidiaBusId = "PCI:0:1:0";
        amdgpuBusId = "PCI:0:7:0";
      };
    };
  };
}

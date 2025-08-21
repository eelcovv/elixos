{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    ../../modules/hardware/efi-boot-at-root.nix
    ../../modules/hardware/efi-dualboot.nix
    ../../modules/hardware/gpu/nvidia.nix
    ../../modules/hardware/gpu/nvidia-wayland-env.nix
    ./hardware-configuration.nix
  ];

  # ESP is mounted at /boot (defined by Disko).
  # Dualboot module is aligned to /boot (with fallback handling).

  # Filesystems & swap are provided by Disko at the host level.
  # No duplicates here.

  services.fstrim.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.nvidia.enable = true;
  hardware.nvidia.driver = "open"; # or "proprietary"

  specialisation = {
    nvidia.configuration = {
      system.nixos.tags = ["nvidia"];
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

  boot.initrd.systemd.enable = true;
  nixpkgs.config.allowUnfree = true;
}

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
    ../../modules/hardware/nvidia-wayland-env.nix
    ../../modules/hardware/nvidia-open.nix
    ./hardware-configuration.nix
  ];

  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  specialisation = {
    on-the-go.configuration = {
      system.nixos.tags = ["on-the-go"];
      hardware.nvidia = {
        prime = {
          sync.enable = lib.mkForce false;
          nvidiaBusId = "PCI:0:1:0";
          amdgpuBusId = "PCI:0:7:0";
          offload.enable = lib.mkForce true;
          offload.enableOffloadCmd = lib.mkForce true;
        };
      };
    };

    nvidea.configuration = {
      system.nixos.tags = ["nvidea"];
      # see https://nixos.wiki/wiki/Nvidia for details on this section
      hardware.nvidia.prime = {
        # use this to be able to switch between amdgpu and nvidia
        #offload = {
        #  enable = true;
        #  enableOffloadCmd = true;
        #};
        # use this to automatically switch between amdgpu and nvidia
        sync.enable = true;
        # Make sure to use the correct Bus ID values for your system!
        # obtain using lshw -c display
        # intelBusId = "PCI:0:2:0"; for intel laptops
        nvidiaBusId = "PCI:0:1:0";
        amdgpuBusId = "PCI:0:7:0";
      };
    };
  };
}

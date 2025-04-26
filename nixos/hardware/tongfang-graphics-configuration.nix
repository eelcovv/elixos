/*
  This NixOS module defines hardware configurations for a Tongfang laptop with
  NVIDIA and AMD GPUs. It provides two specializations for GPU usage:

  1. `on-the-go.configuration`:
     - Designed for scenarios where GPU offloading is required.
     - Disables NVIDIA PRIME synchronization (`sync.enable`).
     - Configures GPU offloading with specific PCI Bus IDs for NVIDIA and AMD GPUs.
     - Enables offloading commands explicitly.

  2. `nvidea.configuration`:
     - Configures NVIDIA PRIME synchronization for automatic GPU switching.
     - Uses specific PCI Bus IDs for NVIDIA and AMD GPUs.
     - Includes commented-out options for manual GPU offloading if needed.
     - References the NixOS Wiki for further details on NVIDIA configuration.

  Notes:
  - Ensure the correct PCI Bus IDs (`nvidiaBusId` and `amdgpuBusId`) are set for your system.
    These can be obtained using the `lshw -c display` command.
  - The `system.nixos.tags` attribute is used to tag configurations for easier identification.
*/
{ config, lib, pkgs, modulesPath, ... }:
{

  specialisation = {
    on-the-go.configuration = {
      system.nixos.tags = [ "on-the-go" ];
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

      system.nixos.tags = [ "nvidea" ];
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


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

  ##########################################################################
  # Bootloader & EFI
  ##########################################################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # The ESP is mounted at /boot (as defined by disko).
  # If your dualboot module expects /boot/efi, adapt that module accordingly.

  ##########################################################################
  # LUKS / initrd
  #
  # Disko sets `initrdUnlock = true` on the root LUKS device, so initrd
  # will handle the passphrase prompt. No need to duplicate entries here.
  ##########################################################################

  ##########################################################################
  # Filesystems & swap
  #
  # Managed by disko via ../../disks/tongfang.nix at the host level.
  # Avoid redefining fileSystems or swapDevices here to prevent conflicts.
  ##########################################################################

  # Enable fstrim for SSDs (works fine with LUKS + allowDiscards).
  services.fstrim.enable = true;

  ##########################################################################
  # Firmware / NVIDIA
  ##########################################################################
  hardware.enableRedistributableFirmware = true;

  hardware.nvidia.enable = true;
  hardware.nvidia.driver = "open"; # or "proprietary" if preferred

  ##########################################################################
  # Specialisations
  #
  # Provide alternate boot configurations for the NVIDIA GPU.
  ##########################################################################
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

  ##########################################################################
  # Quality-of-life settings
  ##########################################################################
  # Use systemd in the initrd for cleaner LUKS + resume handling.
  boot.initrd.systemd.enable = true;

  # Allow unfree packages (Chrome, Spotify, etc.).
  nixpkgs.config.allowUnfree = true;
}

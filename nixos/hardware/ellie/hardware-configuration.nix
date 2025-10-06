# Hardware configuration for "ellie" that matches the singer-style disko setup.
# Uses by-partlabel for LUKS unlock in the initrd.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Core modules (adjust as needed)
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # LUKS devices opened in initrd using Disko's GPT partlabels
  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-partlabel/disk-my-disk-luks-root";
      allowDiscards = true;
    };
    cryptswap = {
      device = "/dev/disk/by-partlabel/disk-my-disk-luks-swap";
      allowDiscards = true;
    };
    crypthome = {
      device = "/dev/disk/by-partlabel/disk-my-disk-luks-home";
      allowDiscards = true;
    };
  };

  # If your swap is inside cryptswap, point resume to its mapper name
  boot.resumeDevice = "/dev/mapper/cryptswap";

  # With Disko managing filesystems, keep this file minimal to avoid conflicts.
}

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

  # Core modules; extend if nodig (e.g. "amdgpu" in userspace, maar niet in initrd)
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [
    "kvm-intel"
  ];
  boot.extraModulePackages = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Microcode (kies AMD of Intel)
  # hardware.cpu.amd.updateMicrocode   = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # LUKS devices openen in initrd op basis van GPT partlabels die Disko aanmaakt:
  # disk.my-disk + partitions.{luks-root,luks-swap,luks-home}  → disk-my-disk-<naam>
  boot.initrd.luks.devices = {
    cryptroot.device = "/dev/disk/by-partlabel/disk-my-disk-luks-root";
    cryptswap.device = "/dev/disk/by-partlabel/disk-my-disk-luks-swap";
  };
  boot.luks.devices.crypthome = {
    device = "/dev/disk/by-partlabel/disk-my-disk-luks-home";
    allowDiscards = true;
  };

  # Optioneel: expliciet hibernate/resume device (swap is versleuteld → via mapper)
  boot.resumeDevice = "/dev/mapper/cryptswap";

  # Met Disko worden fileSystems/swapDevices uit de layout gemount; laat nixos-generate-config
  # hier verder minimaal of verwijder conflicterende entries.
}

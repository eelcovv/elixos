# Hardware configuration for "ellie" matching the disko layout above.
# Uses by-partlabel for initrd LUKS unlock so it remains stable across reorders.
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

  # Kernel/initrd modules: keep minimal; adjust if you know the CPU vendor.
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [
    /*
    e.g. "kvm-amd" or "kvm-intel" if you like
    */
  ];
  boot.extraModulePackages = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # If this is AMD, you can enable microcode like this:
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # For Intel, use:
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Match the GPT partition names from disko for LUKS unlock in initrd
  boot.initrd.luks.devices = {
    cryptroot.device = "/dev/disk/by-partlabel/ellie-root";
    cryptswap.device = "/dev/disk/by-partlabel/ellie-swap";
    crypthome.device = "/dev/disk/by-partlabel/ellie-home";
  };

  # Optional: make resume explicit (not needed if disko set resumeDevice=true)
  # boot.resumeDevice = "/dev/mapper/cryptswap";

  # NOTE:
  # With disko, fileSystems and swapDevices are generated/mounted per the disko spec.
  # You can keep NixOS' generated fileSystems minimal or remove conflicting entries.
}

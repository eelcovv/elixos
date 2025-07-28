/**
* QEMU/KVM virtuele machine kernelmoduleconfiguratie
*
* Deze module configureert de benodigde kernelmodules voor virtuele machines
* die draaien onder QEMU/KVM zoals Contabo VPS’en. Bevat virtio-drivers,
* IDE-fallbacks, USB-ondersteuning, en optioneel bochs-gpu voor virtuele VGA.
*/
{
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "virtio_net"
    "ata_piix"
    "sd_mod"
    "uhci_hcd"
  ];

  boot.initrd.kernelModules = [];

  boot.kernelModules = [
    "virtio_pci"
    "virtio_net"
    "virtio_scsi"
    "bochs_drm"
  ];

  boot.extraModulePackages = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # optioneel:
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

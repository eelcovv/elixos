{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_mmio"
    "9p"
    "9pnet_virtio"
  ];

  boot.initrd.kernelModules = [ "virtio_gpu" ];

  boot.kernelParams = [
    "video=virtio_gpu"
    "video=Virtual-1:2560x1600" # schermresolutie
  ];

  services.xserver.videoDrivers = [ "modesetting" ];
}
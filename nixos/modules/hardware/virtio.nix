/*
  This NixOS module configures hardware support for VirtIO devices, commonly
  used in virtualized environments. Below is a breakdown of the configuration:

  - `boot.initrd.availableKernelModules`: Specifies kernel modules to be included
    in the initial ramdisk for VirtIO support. These modules enable various VirtIO
    functionalities such as block devices, SCSI, and 9p filesystem support.

  - `boot.initrd.kernelModules`: Includes the `virtio_gpu` module in the initial
    ramdisk to support VirtIO GPU devices.

  - `boot.kernelParams`: Adds kernel parameters to configure video output. 
    - `video=virtio_gpu`: Specifies the VirtIO GPU driver for video output.
    - `video=Virtual-1:2560x1600`: Sets the screen resolution to 2560x1600.

  - `services.xserver.videoDrivers`: Configures the X server to use the "modesetting"
    video driver, which is compatible with VirtIO GPU devices.

  This module is intended for use in virtualized environments where VirtIO devices
  are utilized for improved performance and compatibility.
*/

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
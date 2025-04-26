/*
  This NixOS hardware configuration file is tailored for a Tongfang laptop.
  It includes specific hardware settings, bootloader configurations, and
  filesystem definitions.

  - `imports`: Includes additional configuration files:
    - `../modules/profiles/vm-host.nix`: Likely a profile for virtual machine hosting.
    - `./tongfang-hardware-configuration.nix`: Hardware-specific settings for the Tongfang laptop.
    - `./tongfang-graphics-configuration.nix`: Graphics-specific settings for the Tongfang laptop.

  - `boot.loader.systemd-boot.enable`: Enables the systemd-boot bootloader.
  - `boot.loader.efi.canTouchEfiVariables`: Allows the bootloader to modify EFI variables.

  - `boot.initrd.luks.devices`: Configures LUKS encryption for the root filesystem.
    - `luks-f0af0243-70cb-493e-be3c-33a7b3b413ac`: Specifies the encrypted device by UUID.

  - `fileSystems."/boot"`: Configures the `/boot` partition.
    - `device`: Specifies the device by UUID.
    - `fsType`: Filesystem type (ext4).
    - `options`: Mount options for security (restrictive file and directory permissions).

  - `fileSystems."/"`: Configures the root filesystem.
    - `device`: Specifies the LUKS-mapped device.
    - `fsType`: Filesystem type (ext4).

  - `swapDevices`: Configures swap space.
    - `device`: Specifies the swap device by UUID.

  Note: Additional options or configurations from a previous setup can be added
  to this file as needed.
*/
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    # Dit kan een door nixos-generate-config gemaakte hardware config zijn
    ../modules/profiles/vm-host.nix
    ./tongfang-hardware-configuration.nix
    ./tongfang-graphics-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-f0af0243-70cb-493e-be3c-33a7b3b413ac".device = "/dev/disk/by-uuid/f0af0243-70cb-493e-be3c-33a7b3b413ac";

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/C22A-626C";
      fsType = "ext4";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  # Voeg root bestandssysteem toe
  fileSystems."/" =
    {
      device = "/dev/mapper/luks-f0af0243-70cb-493e-be3c-33a7b3b413ac"; # Je LUKS device
      fsType = "ext4";
    };


  # Voeg hier de swap-devices en andere opties uit je oude config toe:
  swapDevices = [
    { device = "/dev/disk/by-uuid/da00c9e6-cb32-4373-a547-cebf069ab7f1"; }
  ];
}

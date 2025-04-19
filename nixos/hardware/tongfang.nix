{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    # Dit kan een door nixos-generate-config gemaakte hardware config zijn
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
      device = "/dev/mapper/luks-f0af0243-70cb-493e-be3c-33a7b3b413ac";  # Je LUKS device
      fsType = "ext4";
    };


  # Voeg hier de swap-devices en andere opties uit je oude config toe:
  swapDevices = [
    { device = "/dev/disk/by-uuid/da00c9e6-cb32-4373-a547-cebf069ab7f1"; }
  ];
}

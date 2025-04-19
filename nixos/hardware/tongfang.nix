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
      device = "/dev/disk/by-uuid/C22A-626C";:1
      fsType = "ext4"; options = [ "fmask=0077" "dmask=0077" ];
    };
}

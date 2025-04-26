{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/hardware/efi-boot.nix
    ../modules/hardware/virtio.nix
  ];
  boot.loader.efi.canTouchEfiVariables = false;
}

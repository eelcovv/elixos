{ pkgs, ... }:

{
  imports = [
    # Dit kan een door nixos-generate-config gemaakte hardware config zijn
    ./contabo-hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = {
    "luks-ef0fc5e3-81cc-4d6d-bd1a-f4746a961c2a".device = "/dev/disk/by-uuid/ef0fc5e3-81cc-4d6d-bd1a-f4746a961c2a";
  };
}

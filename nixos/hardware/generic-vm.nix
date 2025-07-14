/*
This NixOS hardware configuration is tailored for generic virtual machines.

- `imports`: Includes additional hardware-specific modules:
- `../modules/hardware/efi-boot.nix`: Configures EFI boot support.
- `../modules/hardware/virtio.nix`: Enables VirtIO drivers for optimized virtualization performance.

- `boot.loader.efi.canTouchEfiVariables`: Set to `false` to prevent the system
from modifying EFI variables, which is useful in virtualized environments
where such changes might not be supported or necessary.
*/
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../modules/hardware/efi-boot.nix
    ../modules/hardware/virtio.nix
  ];
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
}

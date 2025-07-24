{
  lib,
  config,
  ...
}: {
  imports = [
    ../../modules/hardware/efi-boot-at-root.nix
    ./hardware-configuration.nix.nix
  ];
}

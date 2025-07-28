{
  lib,
  config,
  ...
}: {
  imports = [
    ../../modules/hardware/efi-boot-at-root.nix
    ../../modules/hardware/qemu-virt.nix
  ];
}

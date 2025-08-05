{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    ../../modules/hardware/qemu_virt.nix
    ../../modules/hardware/grub.nix
  ];

  # 🧱 BIOS installation → write GRUB to the MBR of the main disk
  boot.loader.grub.device = "/dev/sda";

  # 📁 Filesystem layout based on Ubuntu 22 default setup
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  # ❌ No separate /boot or /boot/efi partitions needed in legacy boot mode

  # 🧼 Clean /tmp on each reboot (optional, but useful)
  boot.tmp.cleanOnBoot = true;
}

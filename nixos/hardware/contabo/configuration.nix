# this configuration is for Contabo servers using legacy BIOS boot mode
# it sets up GRUB as the bootloader and configures the filesystem layout
# based on a typical Ubuntu 22 setup, without separate /boot or /boot/efi
# partitions, since this is a BIOS system
# it also ensures /tmp is cleaned on each reboot for better security
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

  # 📦 BIOS install — install GRUB to MBR
  boot.loader.grub.device = "/dev/sda";

  # 🧱 Filesystem (Ubuntu-style)
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  # ❌ No separate /boot needed

  boot.tmp.cleanOnBoot = true;
}

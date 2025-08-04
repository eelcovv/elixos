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

  # 🔧 Hostspecifieke bootloader device
  boot.loader.grub.device = "/dev/sda";

  # 📁 Filesystemindeling gebaseerd op Ubuntu
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/sda16";
    fsType = "ext4";
  };
}

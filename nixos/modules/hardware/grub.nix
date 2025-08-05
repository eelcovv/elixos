{
  config,
  lib,
  ...
}: {
  boot.loader = {
    grub.enable = true;
    efiSupport = false; # 🔧 This is a BIOS (non-EFI) setup
    efi.canTouchEfiVariables = false; # 🛑 Disable EFI-specific operations
  };

  boot.loader.systemd-boot.enable = false; # ✅ Not needed on BIOS systems
}

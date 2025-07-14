{
  config,
  lib,
  pkgs,
  ...
}: {
  # Add a custom boot entry for Windows to systemd-boot
  boot.loader.systemd-boot.extraEntries = {
    "windows.conf" = ''
      title Windows
      efi /EFI/Microsoft/Boot/bootmgfw.efi
    '';
  };

  # Set Windows as the default boot entry after each install or rebuild
  # Only if the Windows EFI bootloader is present
  boot.loader.systemd-boot.extraInstallCommands = ''
    if [ -e /boot/efi/EFI/Microsoft/Boot/bootmgfw.efi ]; then
      ${pkgs.systemd}/bin/bootctl set-default windows.conf
    fi
  '';
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  ##########################################################################
  # systemd-boot: extra Windows entry (dual-boot)
  #
  # Assumes the ESP is mounted at /boot (Disko default).
  # We still keep a fallback check for /boot/efi in case a host differs.
  ##########################################################################

  # Create a custom loader entry for Windows
  boot.loader.systemd-boot.extraEntries = {
    "windows.conf" = ''
      title Windows
      # Path is relative to the ESP; this is correct for both /boot and /boot/efi
      efi /EFI/Microsoft/Boot/bootmgfw.efi
    '';
  };

  # After each install/rebuild, set Windows as default IF the Windows EFI exists.
  # Use bootctl with an explicit --esp-path to be robust across mount points.
  boot.loader.systemd-boot.extraInstallCommands = ''
    set -eu

    # Prefer /boot (Disko), but also handle legacy /boot/efi
    ESP=/boot
    if [ ! -e "$ESP/EFI/Microsoft/Boot/bootmgfw.efi" ] && [ -e /boot/efi/EFI/Microsoft/Boot/bootmgfw.efi ]; then
      ESP=/boot/efi
    fi

    if [ -e "$ESP/EFI/Microsoft/Boot/bootmgfw.efi" ]; then
      ${pkgs.systemd}/bin/bootctl --esp-path="$ESP" set-default windows.conf
    fi
  '';
}

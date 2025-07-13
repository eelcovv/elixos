/**
 * Extra options to enable dual boot with windows`
 */
 { config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.extraEntries = {
    "windows.conf" = ''
      title Windows
      efi /EFI/Microsoft/Boot/bootmgfw.efi
    '';
  };

  # Windows as default OS
  boot.loader.systemd-boot.default = "windows.conf";
}

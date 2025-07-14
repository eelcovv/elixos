/**
* Configures the EFI bootloader settings for the system.
*
* This module sets up the system to use the systemd-boot bootloader, which is
* a simple and modern UEFI boot manager. It ensures that the system can manage
* EFI variables and specifies the mount point for the EFI system partition.
*
* Options:
* - `boot.loader.systemd-boot.enable`: Enables the systemd-boot bootloader.
*   Ensure that your system supports UEFI before enabling this option.
* - `boot.loader.efi.canTouchEfiVariables`: Allows the system to modify EFI
*   variables, which is necessary for managing UEFI boot entries.
* - `boot.loader.efi.efiSysMountPoint`: Specifies the mount point of the EFI
*   system partition, typically `/boot/efi`.
*/
{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    systemd-boot.editor = false;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot/efi";
  };
}

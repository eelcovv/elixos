/**
* This NixOS module configures a system to act as a virtual machine (VM) host.
*
* - Adds `OVMF` and `qemu` to the system packages for virtualization support.
* - Configures the system to provide UEFI firmware files (`OVMF_CODE.fd` and `OVMF_VARS.fd`)
*   in the `/etc/firmware` directory, sourced from the `OVMF` package.
*
* Dependencies:
* - `OVMF`: Provides UEFI firmware for virtual machines.
* - `qemu`: A generic and open-source machine emulator and virtualizer.
*/
{
  config,
  pkgs,
  ...
}: let
  ovmf = pkgs.OVMF.fd;
in {
  environment.systemPackages = with pkgs; [
    OVMF
    qemu
  ];

  environment.etc = {
    "firmware/OVMF_CODE.fd".source = "${ovmf}/FV/OVMF_CODE.fd";
    "firmware/OVMF_VARS.fd".source = "${ovmf}/FV/OVMF_VARS.fd";
  };
}

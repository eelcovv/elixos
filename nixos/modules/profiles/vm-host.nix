# nixos/modules/profiles/vm-host.nix
{ config, pkgs, ... }:

let
  ovmf = pkgs.OVMF.fd;
in
{
  environment.systemPackages = with pkgs; [
    OVMF
    qemu
  ];

  environment.etc = {
    "firmware/OVMF_CODE.fd".source = "${ovmf}/FV/OVMF_CODE.fd";
    "firmware/OVMF_VARS.fd".source = "${ovmf}/FV/OVMF_VARS.fd";
  };
}

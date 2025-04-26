{ inputs, lib, config, pkgs, ... }:

{
  imports = [
    ../hardware/singer.nix
    ../disks/singer.nix
    ../modules/common.nix
    ../modules/home-manager.nix
    ../modules/services/generic-vm.nix
  ];

  networking.hostName = "singer";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Amsterdam";

  environment.systemPackages = with pkgs; [
    git
    htop
    vim
    # other basic tools
  ];

  services.openssh.enable = true;
  services.qemuGuest.enable = true;

  users.users.eelco = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPassword = "..."; # Fill with hashed password or use mkpasswd
  };

  system.stateVersion = "24.05"; # Adjust based on your NixOS version
}

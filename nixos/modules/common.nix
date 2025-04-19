{ config, lib, pkgs, ... }:

{
  # Algemene systeeminstellingen
  systemd.services.someService.enable = true;

  # Shell
  programs.zsh.enable = true;

  # X server + GNOME
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.openssh.enable = true;
  services.pipewire.enable = true;
  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Amsterdam";

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
  ];
}

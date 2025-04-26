/*
  This NixOS configuration module defines common system settings:

  - Enables a systemd service (`someService`).
  - Configures the Zsh shell.
  - Sets up the X server with GNOME as the desktop environment and GDM as the display manager.
  - Enables essential services such as OpenSSH, PipeWire, and NetworkManager.
  - Configures localization with `en_US.UTF-8` as the default locale and sets the timezone to `Europe/Amsterdam`.
  - Specifies a list of system packages to be installed, including `vim`, `git`, `curl`, and `just`.
*/
{ config, lib, pkgs, ... }:

{
 # General system settings

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
    just
  ];
}

/*
  This NixOS configuration module defines common system settings:

  - Enables a systemd service (`someService`).
  - Configures the Zsh shell.
  - Sets up the X server with GNOME as the desktop environment and GDM as the display manager.
  - Enables essential services such as OpenSSH, PipeWire, and NetworkManager.
  - Configures localization with `en_US.UTF-8` as the default locale and sets the timezone to `Europe/Amsterdam`.
  - Specifies a list of system packages to be installed, including `vim`, `git`, `curl`, and `just`.
*/
{ config, lib, pkgs, inputs, ... }:



{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  # Flakes support
  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };




  # General system settings

  # Shell
  programs.zsh.enable = true;

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
    agenix-cli
    age
    home-manager
  ];

  system.stateVersion = "24.11";

}

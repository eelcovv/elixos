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
    inputs.home-manager.nixosModules.home-manager
  ];

  options = {
    globalSshClientUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "eelco" ];
      description = "List of users who have SSH client keys.";
    };
    configuredUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of users to configure via Home Manager and other modules.";
    };
  };

  config = {

    # Flakes support
    nix = {
      package = pkgs.nix;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };

    # General system settings

    programs.zsh.enable = true;

    services.openssh.enable = true;
    services.pipewire.enable = true;
    networking.networkmanager.enable = true;

    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "Europe/Amsterdam";

    environment.systemPackages =
      with pkgs;
      let
        inherit (config.system) build;
      in
      [
        vim
        git
        curl
        just
        home-manager
        sops
        yq # needed for extracting your sops key
        rage
      ];

    system.stateVersion = "24.11";

  };
}

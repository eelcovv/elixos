/*
This NixOS configuration module defines common system settings:

- Enables a systemd service (`someService`).
- Configures the Zsh shell.
- Sets up the X server with GNOME as the desktop environment and GDM as the display manager.
- Enables essential services such as OpenSSH, PipeWire, and NetworkManager.
- Configures localization with `en_US.UTF-8` as the default locale and sets the timezone to `Europe/Amsterdam`.
- Specifies a list of system packages to be installed, including `vim`, `git`, `curl`, and `just`.
*/
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    lib/conditional-secrets.nix
  ];

  options = {
    globalSshClientUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["eelco"];
      description = "List of users who have SSH client keys.";
    };

    configuredUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of users to configure via Home Manager and other modules.";
    };

    desktop.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this system is a desktop system with a GUI.";
    };
  };

  config = {
    # Allow HM to replace files under ~/.config
    home-manager.backupFileExtension = "hm-bak";

    # Group to grant repo access
    users.groups.elixos = {};

    # Flakes support
    nix = {
      package = pkgs.nix;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than +3";
      };
    };

    nixpkgs = {config.allowUnfree = true;};

    programs.zsh.enable = true;
    programs.dconf.enable = true;

    services.openssh.enable = true;
    services.pipewire.enable = true;
    networking.networkmanager.enable = true;

    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "Europe/Amsterdam";

    fonts = lib.mkIf config.desktop.enable {
      enableDefaultPackages = true;
      fontconfig.enable = true;
      packages = with pkgs; [
        noto-fonts
        noto-fonts-emoji
        font-awesome
      ];
    };

    environment.localBinInPath = true;

    environment.systemPackages = with pkgs; [
      bashInteractive
      coreutils
      curl
      git
      home-manager
      just
      ntfs3g
      parted
      rage
      ripgrep
      sops
      trash-cli
      util-linux
      vim
      yq
      zsh
    ];

    system.stateVersion = "24.11";
  };
}

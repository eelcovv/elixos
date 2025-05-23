{ config, pkgs, lib, ... }:

{
  options.desktop.enableGnome = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable GNOME desktop";
  };

  options.desktop.enableKde = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable KDE Plasma desktop";
  };

  options.desktop.enableHyperland = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Hyperland desktop";
  };

  config = lib.mkMerge [
    # GNOME
    (lib.mkIf config.desktop.enableGnome {
      services.xserver.enable = true;
      services.xserver.desktopManager.gnome.enable = true;
    })

    # KDE
    (lib.mkIf config.desktop.enableKde {
      services.xserver.enable = true;
      services.desktopManager.plasma6.enable = true;
    })

    # Hyperland
    (lib.mkIf config.desktop.enableHyperland {
      programs.hyprland.enable = true;
    })

    # Set GDM as the only display manager if a desktop is active
    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde) {
      # force the display manager to be gdm
      services.xserver.displayManager.gdm.enable = true;

      # force the password prompt to be gnome's askpass
      programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
    })
  ];
}


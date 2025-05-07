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
    (lib.mkIf config.desktop.enableGnome {
      services.xserver.enable = true;
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;
    })

    (lib.mkIf config.desktop.enableKde {
      services.xserver.enable = true;
      services.xserver.displayManager.sddm.enable = true;
      services.xserver.desktopManager.plasma5.enable = true;
    })

    (lib.mkIf config.desktop.enableHyperland {
      programs.hyprland.enable = true;
    })
  ];
}

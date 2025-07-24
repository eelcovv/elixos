{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    # Fonts
    (import ../fonts/default.nix {inherit pkgs;}).config

    # GNOME: verwacht alleen lib en pkgs
    (lib.mkIf config.desktop.enableGnome (
      (import ./gnome.nix {inherit lib pkgs;}).config
    ))

    # KDE Plasma: vereist ook config
    (lib.mkIf config.desktop.enableKde (
      lib.mkMerge [
        (import ./kde.nix {inherit lib pkgs config;}).config
        (import ./wayland-session.nix {inherit lib pkgs config;})
        (import ./start-keyring-daemon.nix {inherit lib pkgs config;})
      ]
    ))

    # Hyprland: vereist ook config
    (lib.mkIf config.desktop.enableHyperland (
      lib.mkMerge [
        (import ./hyperland.nix {inherit lib pkgs config;}).config
        (import ./wayland-session.nix {inherit lib pkgs config;})
        (import ./start-keyring-daemon.nix {inherit lib pkgs config;})
      ]
    ))

    # GDM + ssh-askpass indien een desktop actief is
    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde || config.desktop.enableHyperland) {
      services.displayManager.gdm.enable = true;
      services.displayManager.autoLogin.enable = false;
      services.displayManager.autoLogin.user = lib.mkForce null;

      programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
    })

    # GNOME XDG-variabelen
    (lib.mkIf config.desktop.enableGnome {
      environment.sessionVariables = {
        XDG_CURRENT_DESKTOP = "GNOME";
        XDG_SESSION_DESKTOP = "GNOME";
      };
    })

    # KDE XDG-variabelen
    (lib.mkIf config.desktop.enableKde {
      environment.sessionVariables = {
        XDG_CURRENT_DESKTOP = "KDE";
        XDG_SESSION_DESKTOP = "KDE";
      };
    })

    # Hyprland XDG-variabelen
    (lib.mkIf config.desktop.enableHyperland {
      environment.sessionVariables = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XCURSOR_SIZE = "24";
      };
    })
  ];
}

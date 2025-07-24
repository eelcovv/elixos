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

    # GDM + askpass alleen als een desktop actief is
    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde || config.desktop.enableHyperland) {
      services.displayManager.gdm.enable = true;
      services.displayManager.autoLogin.enable = false;
      services.displayManager.autoLogin.user = lib.mkForce null;

      programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
    })

    # Zet XDG variabelen afhankelijk van actieve desktop
    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde || config.desktop.enableHyperland) {
      environment.sessionVariables = lib.mkMerge [
        (lib.mkIf config.desktop.enableGnome {
          XDG_CURRENT_DESKTOP = "GNOME";
          XDG_SESSION_DESKTOP = "GNOME";
        })
        (lib.mkIf config.desktop.enableKde {
          XDG_CURRENT_DESKTOP = "KDE";
          XDG_SESSION_DESKTOP = "KDE";
        })
        (lib.mkIf config.desktop.enableHyperland {
          XDG_CURRENT_DESKTOP = "Hyprland";
          XDG_SESSION_DESKTOP = "Hyprland";
          XDG_SESSION_TYPE = "wayland";
          XCURSOR_SIZE = "24";
        })
      ];
    })
  ];
}

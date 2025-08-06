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

        # ✅ Toevoegen van Plasma X11 sessie met correct 'manage' veld
        {
          services.xserver.displayManager.session = [
            {
              name = "plasma-x11";
              start = "exec startplasma-x11";
              manage = "desktop";
            }
          ];
        }
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

    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde || config.desktop.enableHyperland) {
      services.displayManager.gdm = {
        enable = true;
        wayland = true;
      };

      services.displayManager.autoLogin = {
        enable = false;
        user = null;
      };

      programs.ssh.askPassword = "${pkgs.openssh}/libexec/ssh-askpass";
    })
  ];
}

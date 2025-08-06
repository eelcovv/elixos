{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    # Fonts
    (import ../fonts/default.nix {inherit pkgs;}).config

    # GNOME
    (lib.mkIf config.desktop.enableGnome (
      (import ./gnome.nix {inherit lib pkgs;}).config
    ))

    # KDE Plasma
    (lib.mkIf config.desktop.enableKde (
      lib.mkMerge [
        (import ./kde.nix {inherit lib pkgs config;}).config
        (import ./wayland-session.nix {inherit lib pkgs config;})
        (import ./start-keyring-daemon.nix {inherit lib pkgs config;})
      ]
    ))

    # Hyprland
    (lib.mkIf config.desktop.enableHyperland (
      lib.mkMerge [
        (import ./hyperland.nix {inherit lib pkgs config;}).config
        (import ./wayland-session.nix {inherit lib pkgs config;})
        (import ./start-keyring-daemon.nix {inherit lib pkgs config;})
      ]
    ))
    # GDM + SSH prompt
    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde || config.desktop.enableHyperland) {
      services.displayManager.gdm = {
        enable = true;
        wayland = lib.mkForce false;
      };

      services.xserver.displayManager.defaultSession = "plasma";

      services.xserver.displayManager.sessionPackages = [
        pkgs.kdePackages.plasma-workspace
      ];

      services.displayManager.autoLogin = {
        enable = false;
        user = null;
      };

      programs.ssh.askPassword = "${pkgs.openssh}/libexec/ssh-askpass";
    })
  ];
}

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
  ];
}

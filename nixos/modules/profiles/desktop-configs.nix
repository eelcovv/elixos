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
      (import ./gnome.nix {inherit lib pkgs config;}).config
    ))

    # KDE Plasma
    (lib.mkIf config.desktop.enableKde (
      lib.mkMerge [
        (import ./kde.nix {inherit lib pkgs config;}).config
        (import ./wayland-session.nix {inherit config lib pkgs;})
        (import ./start-keyring-daemon.nix {inherit config lib pkgs;})
      ]
    ))

    # Hyprland
    (lib.mkIf config.desktop.enableHyperland (
      lib.mkMerge [
        (import ./hyperland.nix {inherit config lib pkgs;}).config
        (import ./wayland-session.nix {inherit config lib pkgs;})
        (import ./start-keyring-daemon.nix {inherit config lib pkgs;})
      ]
    ))

    # GDM & SSH-askpass: alleen als één van de desktops aanstaat
    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde || config.desktop.enableHyperland) {
      services.displayManager.gdm.enable = true;
      services.displayManager.autoLogin.enable = false;
      services.displayManager.autoLogin.user = lib.mkForce null;

      programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
    })
  ];
}

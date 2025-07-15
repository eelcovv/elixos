{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    (import ./fonts/defaults.nix {inherit pkgs;}).config

    (lib.mkIf config.desktop.enableGnome (
      (import ./gnome.nix {inherit lib pkgs;}).config
    ))

    (lib.mkIf config.desktop.enableKde (
      lib.mkMerge [
        (import ./kde.nix {inherit lib pkgs;}).config
        (import ./wayland-session.nix {inherit config lib pkgs;})
      ]
    ))

    (lib.mkIf config.desktop.enableHyperland (
      lib.mkMerge [
        (import ./hyperland.nix {inherit config lib pkgs;})
        (import ./wayland-session.nix {inherit config lib pkgs;})
      ]
    ))

    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde) {
      services.displayManager.gdm.enable = true;
      services.xserver.displayManager.gdm.autoLogin.enable = false;
      services.xserver.displayManager.gdm.autoLogin.user = lib.mkForce null;

      programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
    })
  ];
}

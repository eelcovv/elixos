{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.desktop.enableGnome (
      (import ./gnome.nix {inherit lib pkgs;}).config
    ))

    (lib.mkIf config.desktop.enableKde (
      (import ./kde.nix {inherit lib pkgs;}).config
    ))

    (lib.mkIf config.desktop.enableHyperland (
      (import ./hyperland.nix {inherit lib pkgs;}).config
    ))

    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde) {
      services.displayManager.gdm.enable = true;
      services.xserver.displayManager.gdm.autoLogin.enable = false;
      services.xserver.displayManager.gdm.autoLogin.user = lib.mkForce null;

      programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
    })
  ];
}

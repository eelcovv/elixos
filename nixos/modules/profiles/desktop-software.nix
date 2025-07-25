{
  config,
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs;
    [
      vlc
      gimp
      filezilla
      krita
      seahorse
      libsecret
      gnome-keyring
    ]
    ++ lib.optionals config.desktop.enableKde [pkgs.kdePackages.bluedevil]
    ++ lib.optionals config.desktop.enableHyperland [pkgs.blueman]
    ++ lib.optionals config.desktop.enableGnome [pkgs.gnome-bluetooth];
}

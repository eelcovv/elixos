{
  config,
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs;
    [
      firefox
      google-chrome
      vlc
      libreoffice
      gimp
      filezilla
      krita
      seahorse
      libsecret
    ]
    ++ lib.optionals config.desktop.enableKde [pkgs.kdePackages.bluedevil]
    ++ lib.optionals config.desktop.enableHyperland [pkgs.blueman]
    ++ lib.optionals config.desktop.enableGnome [pkgs.gnome.gnome-bluetooth];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}

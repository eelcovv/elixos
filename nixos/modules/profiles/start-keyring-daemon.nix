{
  config,
  lib,
  pkgs,
  ...
}: {
  services.gnome.gnome-keyring.enable = true;
}

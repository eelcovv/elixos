{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./ssh-config.nix
    ./vpn-config.nix
    ./keeweb.nix
  ];

  home.packages = with pkgs; [
    gnome-keyring
    veracrypt
    omnissa-horizon-client
  ];
}

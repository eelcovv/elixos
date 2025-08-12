{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./ssh-config.nix
    ./vpn-config.nix
  ];

  home.packages = with pkgs; [
    gnome-keyring
    keeweb
    veracrypt
    vmware-horizon-client
  ];
}

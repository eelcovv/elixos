{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./ssh-and-surfshark.nix
  ];

  home.packages = with pkgs; [
    gnome-keyring
    keeweb
    veracrypt
    vmware-horizon-client
  ];
}

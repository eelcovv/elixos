{pkgs, ...}: {
  home.packages = with pkgs; [
    gnome-keyring
    keeweb
    veracrypt
    vmware-horizon-client
  ];
}

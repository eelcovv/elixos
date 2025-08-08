{ pkgs, ... }:
{
  home.packages = with pkgs; [
    keeweb
    vmware-horizon-client
    veracrypt
  ];
}

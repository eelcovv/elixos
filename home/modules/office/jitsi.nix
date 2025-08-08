{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jitsi
    # jitsi-meet 
  ];
}

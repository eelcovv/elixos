{pkgs, ...}: {
  home.packages = with pkgs; [
    remmina # GUI remote desktop client (RDP, VNC, SSH, SPICE, etc.)
  ];
}

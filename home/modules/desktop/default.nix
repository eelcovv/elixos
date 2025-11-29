{pkgs, ...}: {
  imports = [
    ./clipboard.nix
    ./notifications.nix
    ./tray.nix
    ./mimetypes.nix
  ];

  home.packages = with pkgs; [
    nautilus
    polkit_gnome
    brightnessctl
    matugen
    wallust
    waypaper
  ];
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  # Hyprland aanzetten
  programs.hyprland.enable = true;

  # Extra software en tools
  environment.systemPackages = with pkgs; [
    hyprpaper
    waybar
    rofi-wayland
    foot
    kitty
    duns
    networkmanagerapplet
    wl-clipboard
    brightnessctl
    grim
    slurp
    pavucontrol
    neofetch
    htop
  ];

  # Zet environment variabelen voor Wayland goed
  environment.sessionVariables = lib.mkMerge [
    {
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    }
  ];
}

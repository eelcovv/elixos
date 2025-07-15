{
  config,
  pkgs,
  lib,
  ...
}: {
  # Hyprland aanzetten
  programs.hyprland.enable = true;

  # Fonts installeren voor betere weergave in bv. Chrome
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    (nerdfonts.override {fonts = ["FiraCode" "JetBrainsMono"];})
  ];

  # Extra software en tools
  environment.systemPackages = with pkgs; [
    hyprpaper
    waybar
    rofi-wayland
    foot
    kitty
    dunst
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

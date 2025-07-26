{
  config,
  pkgs,
  ...
}: let
  wallpaperPath = ./wallpapers/nixos.png;
  hyprDir = ./.;
in {
  xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
  xdg.configFile."hypr/hyprpaper.conf".source = "${hyprDir}/hyprpaper.conf";
  xdg.configFile."waybar/config.jsonc".source = "${hyprDir}/waybar.jsonc";
  xdg.configFile."waybar/style.css".source = "${hyprDir}/waybar.css";

  xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";

  xdg.configFile."hypr/conf".source = "${hyprDir}/conf";

  xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
  xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

  # Zorg dat de wallpaper beschikbaar is
  home.file."Pictures/wallpapers/nixos.png".source = wallpaperPath;

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${"$XDG_RUNTIME_DIR"}/keyring/ssh";

    # Wayland-optimale instellingen
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # Install extra packages
  home.packages = with pkgs; [
    kitty
    rofi-wayland
    hyprpaper
    hyprshot
    hyprlock
    hypridle
    wofi
    waybar
    swaynotificationcenter
    dunst
    brightnessctl
    pavucontrol
    wl-clipboard
  ];
}

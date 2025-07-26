{
  config,
  pkgs,
  ...
}: let
  hyprDir = ./.;
  wallpaperDir = ./wallpapers;
  waypaperIni = ./waypaper.ini;
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

  xdg.configFile."hypr/wallpapers/default.jpg".source = ./wallpapers/nixos.png;
  xdg.configFile."waypaper/config.ini".source = "${hyprDir}/waypaper.ini";

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
    rofimoji
    waybar
    swaynotificationcenter
    dunst
    brightnessctl
    pavucontrol
    wl-clipboard
  ];
}

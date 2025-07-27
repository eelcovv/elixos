{
  config,
  pkgs,
  ...
}: let
  # Determine the selected theme from the environment variable or default to "default"
  selectedTheme = let
    envTheme = builtins.getEnv "HOME_THEME";
  in
    if envTheme == ""
    then "default"
    else envTheme;

  hyprDir = ./.;
  rofiDir = ./rofi;
  wallpaperDir = ./wallpapers;
  wallpaperTargetDir = "${config.xdg.configHome}/wallpapers";

  rofiThemePath = ./rofi/themes/${selectedTheme};
  waybarThemePath = ./waybar/themes/${selectedTheme};

  sharedModules = ./waybar/modules.jsonc;
in {
  # Set environment variable so scripts can use it
  home.sessionVariables.WALLPAPER_DIR = wallpaperTargetDir;

  xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";

  xdg.configFile."waybar/config.jsonc".source = "${waybarThemePath}/config.jsonc";
  xdg.configFile."waybar/style.css".source = "${waybarThemePath}/style.css";

  xdg.configFile."waybar/modules.jsonc".source = sharedModules;

  xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";

  xdg.configFile."hypr/conf".source = "${hyprDir}/conf";

  xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
  xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

  xdg.configFile."rofi/config.rasi".source = "${rofiThemePath}/config.rasi";
  xdg.configFile."rofi/colors.rasi".source = "${rofiThemePath}/colors.rasi";

  # Copy the actual wallpaper to the right location
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${wallpaperTargetDir}/default.jpg
    wallpaper = ,${wallpaperTargetDir}/default.jpg
    splash = false
  '';
  xdg.configFile."wallpapers/default.jpg".source = "${wallpaperDir}/nixos.png";
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
    cliphist
  ];
}

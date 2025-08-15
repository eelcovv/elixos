{
  config,
  pkgs,
  lib,
  ...
}: let
  hyprDir = ./.;
  wallpaperDir = ./wallpapers;
  wallpaperTargetDir = "${config.xdg.configHome}/wallpapers";
in {
  # Unconditional imports to avoid dependency cycles on `config.*`
  imports = [
    ./waybar
    ./waypaper
  ];

  # All actual settings live under `config = { ... };`
  config = {
    ################################
    # Packages for Hyprland and desktop tools
    ################################
    home.packages = with pkgs; [
      kitty
      hyprpaper
      hyprshot
      hyprlock
      hypridle
      wofi
      brightnessctl
      pavucontrol
      wl-clipboard
      cliphist
      # Wallpaper/theme tools (these can also live in the waypaper module;
      # harmless to keep here if you prefer)
      matugen
      wallust
      waypaper
    ];

    systemd.user.targets."hyprland-session" = {
      Unit = {
        Description = "Hyprland graphical session (user)";
        Requires = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    programs.waybar.enable = true;
    programs.waybar.systemd.enable = true;
    programs.waybar.systemd.target = "hyprland-session.target";

    ################################
    # Session environment variables
    ################################
    home.sessionVariables = {
      WALLPAPER_DIR = wallpaperTargetDir;
      SSH_AUTH_SOCK = "${"$XDG_RUNTIME_DIR"}/keyring/ssh"; # keep literal for runtime expansion
      # ROFI_CONFIG is set inside the Waybar submodule
    };

    ################################
    # Hyprland configuration files
    ################################
    xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
    xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
    xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
    xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
    xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
    xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
    xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

    ################################
    # Shared helper functions (used by Waybar/Waypaper)
    ################################

    home.file.".config/hypr/scripts/helper-functions.sh" = {
      source = "${hyprDir}/scripts/helper-functions.sh";
      executable = true;
    };

    ################################
    # Hyprpaper defaults (base wallpaper)
    ################################
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ${wallpaperTargetDir}/default.png
      wallpaper = ,${wallpaperTargetDir}/default.png
      splash = false
    '';

    # Provide a default wallpaper image
    xdg.configFile."wallpapers/default.png".source = "${wallpaperDir}/nixos.png";

    ################################
    # Ensure ~/.local/bin is in PATH
    ################################
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

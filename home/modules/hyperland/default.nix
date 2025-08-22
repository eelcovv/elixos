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
  imports = [
    ./waybar
    ./waypaper
  ];

  config = {
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
      matugen
      wallust
      waypaper
    ];

    # Hyprland session target (user)
    systemd.user.targets."hyprland-session" = {
      Unit = {
        Description = "Hyprland graphical session (user)";
        Requires = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Install = {WantedBy = ["default.target"];};
    };

    # Notifications via systemd
    systemd.user.services."swaync" = {
      Unit = {
        Description = "SwayNotificationCenter";
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    home.sessionVariables = {
      WALLPAPER_DIR = wallpaperTargetDir;
      SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
    };

    # Hyprland configs
    xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
    xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
    xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
    xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
    xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
    xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
    xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

    # Sanity check: helper must exist
    home.activation.checkHyprHelper = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [ ! -r "$HOME/.config/hypr/scripts/helper-functions.sh" ]; then
        echo "ERROR: missing helper at ~/.config/hypr/scripts/helper-functions.sh" >&2
        exit 1
      fi
    '';

    # hyprpaper config + default wallpaper (Waypaper controls runtime)
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      ipc = on
      splash = false
      # preload = ${wallpaperTargetDir}/default.png
    '';
    xdg.configFile."${wallpaperTargetDir}/default.png".source = "${wallpaperDir}/nixos.png";

    # PATH
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];

    # Waypaper options (consumed by ./waypaper)
    hyprland.wallpaper.enable = true;
    hyprland.wallpaper.random.enable = true;
    hyprland.wallpaper.random.intervalSeconds = 1800;

    hyprland.wallpaper.fetch.enable = true;
    hyprland.wallpaper.fetch.onCalendar = "daily";
  };
}

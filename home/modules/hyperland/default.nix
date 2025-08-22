{
  config,
  pkgs,
  lib,
  ...
}: let
  hyprDir = ./.;
  scriptsDir = "${hyprDir}/scripts";
  wallpaperDir = ./wallpapers;

  # Mutable wallpapers live here (user config dir)
  wallpaperTargetDir = "${config.xdg.configHome}/wallpapers";
  defaultWallpaper = "${wallpaperTargetDir}/default.png";
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
      inotify-tools
      wofi
      brightnessctl
      pavucontrol
      wl-clipboard
      cliphist
      matugen
      wallust
      waypaper
      imagemagick # for fallback wallpaper creation
    ];

    # ---------------------------
    # Hyprland user session target
    # ---------------------------
    systemd.user.targets."hyprland-session" = {
      Unit = {
        Description = "Hyprland graphical session (user)";
        Requires = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Install = {WantedBy = ["default.target"];};
    };

    # ---------------------------
    # Notifications (SwayNC)
    # ---------------------------
    systemd.user.services."swaync" = {
      Unit = {
        Description = "SwayNotificationCenter";
        PartOf = ["hyprland-session.target"];
        After = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    # -------------------------------------------------------
    # Ensure ~/.local/bin ends up in the systemd user PATH
    # -------------------------------------------------------
    systemd.user.services."import-user-env" = {
      Unit = {
        Description = "Import PATH into systemd user environment";
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        Environment = [
          "PATH=%h/.local/bin:%h/.nix-profile/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/bin:/bin"
        ];
        ExecStart = "${pkgs.systemd}/bin/systemctl --user import-environment PATH";
        RemainAfterExit = true;
      };
      Install = {WantedBy = ["default.target"];};
    };

    # ---------------------------
    # Session environment
    # ---------------------------
    home.sessionVariables = {
      WALLPAPER_DIR = wallpaperTargetDir;
      SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
    };

    # ---------------------------
    # Hyprland config files
    # ---------------------------
    xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
    xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
    xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
    xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
    xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
    xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
    xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

    # Fail early if helper is missing
    home.activation.checkHyprHelper = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [ ! -r "$HOME/.config/hypr/scripts/helper-functions.sh" ]; then
        echo "ERROR: missing helper at ~/.config/hypr/scripts/helper-functions.sh" >&2
        exit 1
      fi
    '';

    # ---------------------------
    # Display watcher utilities
    # ---------------------------
    home.file.".local/bin/hypr-switch-displays" = {
      source = "${scriptsDir}/hypr-switch-displays.sh";
      executable = true;
    };
    home.file.".local/bin/hypr-display-watcher" = {
      text = builtins.readFile ./scripts/hypr-display-watcher.sh;
      executable = true;
    };
    systemd.user.services."hypr-display-watcher" = {
      Unit = {
        Description = "Auto switch displays on hotplug (Hyprland)";
        PartOf = ["hyprland-session.target"];
        After = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "%h/.local/bin/hypr-display-watcher";
        Restart = "always";
        RestartSec = 1;
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    # ---------------------------
    # Hyprpaper: single wallpaper manager (daemon)
    # ---------------------------

    # Config file for hyprpaper
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      # hyprpaper uses a single global wallpaper; IPC on enables tooling to switch later.
      ipc = on
      splash = false
      preload = ${defaultWallpaper}
      wallpaper = ,${defaultWallpaper}
    '';

    # Provide default wallpaper from repo (nixos.png)
    xdg.configFile."${defaultWallpaper}".source = "${wallpaperDir}/nixos.png";

    # Create a fallback if missing (first deploy or manual delete)
    home.activation.ensureDefaultWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${wallpaperTargetDir}"
      if [ ! -f "${defaultWallpaper}" ]; then
        echo "Creating fallback wallpaper at ${defaultWallpaper}"
        "${pkgs.imagemagick}/bin/convert" -size 3840x2160 xc:'#202020' "${defaultWallpaper}"
      fi
    '';

    # Start hyprpaper inside Hyprland session only
    systemd.user.services.hyprpaper = {
      Unit = {
        Description = "Hyprland wallpaper daemon (hyprpaper)";
        After = ["graphical-session.target" "hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "simple";
        Environment = [
          "XDG_RUNTIME_DIR=%t"
          "WAYLAND_DISPLAY=wayland-0"
        ];
        ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper -c ${config.xdg.configHome}/hypr/hyprpaper.conf";
        Restart = "on-failure";
        RestartSec = "2s";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    # Make sure no legacy randomizer/timer is enabled (avoid conflicts)
    systemd.user.services."waypaper-random".Install.WantedBy = lib.mkForce [];
    systemd.user.timers."waypaper-random".Install.WantedBy = lib.mkForce [];

    # Best-effort: disable/stop dangling units if present
    home.activation.disableOtherWallpaperUnits = lib.hm.dag.entryAfter ["reloadSystemd"] ''
      systemctl --user disable --now waypaper-random.service 2>/dev/null || true
      systemctl --user disable --now waypaper-random.timer   2>/dev/null || true
    '';

    # Ensure ~/.local/bin in PATH for interactive session
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];

    # Keep your module options for future use (no effect on service wiring here)
    hyprland.wallpaper.enable = true;
    hyprland.wallpaper.random.enable = true;
    hyprland.wallpaper.random.intervalSeconds = 1800;
    hyprland.wallpaper.fetch.enable = true;
    hyprland.wallpaper.fetch.onCalendar = "daily";
  };
}

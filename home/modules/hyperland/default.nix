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

  # Wait until Hyprland answers to hyprctl (prevents early-start failures)
  waitForHypr = pkgs.writeShellScript "wait-for-hypr" ''
    for i in $(seq 1 60); do
      if ${pkgs.hyprland}/bin/hyprctl -j monitors >/dev/null 2>&1; then
        exit 0
      fi
      sleep 0.25
    done
    # Do not fail the service; just continue (Hyprland target should guard anyway)
    exit 0
  '';
in {
  imports = [
    ./waybar
    ./waypaper
    ./xdg.desktopEntries.nix
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

    # Hyprland user session target
    systemd.user.targets."hyprland-session" = {
      Unit = {
        Description = "Hyprland graphical session (user)";
      };
    };

    # Notifications (SwayNC)
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

    # Ensure ~/.local/bin ends up in the systemd user PATH
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

    # Session environment
    home.sessionVariables = {
      WALLPAPER_DIR = wallpaperTargetDir;
      SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
    };

    # Hyprland config files
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

    # Display watcher utilities
    home.file.".local/bin/hypr-switch-displays" = {
      source = "${scriptsDir}/hypr-switch-displays.sh";
      executable = true;
    };
    home.file.".local/bin/hypr-display-watcher" = {
      source = "${scriptsDir}/hypr-display-watcher.sh";
      executable = true;
    };

    home.file.".local/bin/hyprshot-launcher" = {
      source = "${scriptsDir}/hyprshot-launcher.sh";
      executable = true;
    };

    # Expose calculator script from ./scripts to ~/.local/bin
    home.file.".local/bin/calculator" = {
      source = "${scriptsDir}/calculator.sh";
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

    # Hyprpaper: single wallpaper manager (daemon)
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      ipc = on
      splash = false
      preload = ${defaultWallpaper}
      wallpaper = ,${defaultWallpaper}
    '';

    xdg.configFile."${defaultWallpaper}".source = "${wallpaperDir}/nixos.png";

    home.activation.ensureDefaultWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${wallpaperTargetDir}"
      if [ ! -f "${defaultWallpaper}" ]; then
        echo "Creating fallback wallpaper at ${defaultWallpaper}"
        "${pkgs.imagemagick}/bin/convert" -size 3840x2160 xc:'#202020' "${defaultWallpaper}"
      fi
    '';

    systemd.user.services.hyprpaper = {
      Unit = {
        Description = "Hyprland wallpaper daemon (hyprpaper)";
        After = ["graphical-session.target" "hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
        ConditionPathExistsGlob = "%t/hypr/*";
      };
      Service = {
        Type = "simple";
        ExecStartPre = "${waitForHypr}";
        Environment = ["XDG_RUNTIME_DIR=%t"];
        ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper -c ${config.xdg.configHome}/hypr/hyprpaper.conf";
        Restart = "on-failure";
        RestartSec = "2s";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    # Cleanup legacy wallpaper timers
    home.activation.purgeLegacyWallpaperUnits = lib.hm.dag.entryAfter ["reloadSystemd"] ''
      systemctl --user stop    waypaper-random.service 2>/dev/null || true
      systemctl --user stop    waypaper-random.timer   2>/dev/null || true
      systemctl --user disable waypaper-random.service 2>/dev/null || true
      systemctl --user disable waypaper-random.timer   2>/dev/null || true
      systemctl --user mask    waypaper-random.service 2>/dev/null || true
      systemctl --user mask    waypaper-random.timer   2>/dev/null || true

      rm -f "$HOME/.config/systemd/user/waypaper-random.service" 2>/dev/null || true
      rm -f "$HOME/.config/systemd/user/waypaper-random.timer"   2>/dev/null || true
    '';

    home.activation.resetFailedWallpaperUnits = lib.hm.dag.entryAfter ["reloadSystemd"] ''
      systemctl --user reset-failed hyprpaper.service 2>/dev/null || true
    '';

    home.sessionPath = lib.mkAfter ["$HOME/.config/hypr/scripts"];

    # Wallpaper options (have no effect on wiring here)
    hyprland.wallpaper.enable = true;
    hyprland.wallpaper.random.enable = true;
    hyprland.wallpaper.random.intervalSeconds = 1800;
    hyprland.wallpaper.fetch.enable = true;
    hyprland.wallpaper.fetch.onCalendar = "daily";
  };
}

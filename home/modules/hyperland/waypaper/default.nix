{
  config,
  pkgs,
  lib,
  ...
}: let
  scriptsDir = ./scripts;

  # Install ./scripts/<name> -> ~/.local/bin/<name>
  installScript = name: {
    ".local/bin/${name}" = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };

  default_effect = "off\n";
  default_blur = "50x30\n";
  default_automation_interval = "300\n";
in {
  options = {
    hyprland.wallpaper.enable =
      lib.mkEnableOption "Enable Hyprland wallpaper tools (Waypaper + helpers)";

    # Random rotation
    hyprland.wallpaper.random.enable = lib.mkEnableOption "Rotate wallpapers randomly via a systemd timer";
    hyprland.wallpaper.random.intervalSeconds = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Interval (seconds) for the random wallpaper timer.";
    };

    # Fetch wallpapers from repo
    hyprland.wallpaper.fetch.enable = lib.mkEnableOption "Periodically fetch wallpapers using fetch-wallpapers.sh";
    hyprland.wallpaper.fetch.onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "weekly"; # e.g. "daily", "hourly", "Mon,Fri 08:00", "00/30:00" (every 30 min)
      description = "systemd OnCalendar schedule for wallpaper fetch timer.";
    };
  };

  config = lib.mkIf config.hyprland.wallpaper.enable {
    ############################
    # Do NOT auto-start user units during `nixos-rebuild switch`
    # This avoids HM blocking on GUI units (Wayland not ready yet).
    ############################
    systemd.user.startServices = false;

    ############################
    # Packages
    ############################
    home.packages =
      (with pkgs; [
        waypaper
        hyprpaper
        imagemagick
        wallust
        matugen
        rofi-wayland
        libnotify
        swaynotificationcenter
        git
        nwg-dock-hyprland
      ])
      ++ lib.optionals (pkgs ? pywalfox) [pkgs.pywalfox];

    ############################
    # Scripts -> ~/.local/bin
    ############################
    home.file = lib.mkMerge [
      (installScript "wallpaper.sh")
      (installScript "wallpaper-restore.sh")
      (installScript "wallpaper-effects.sh")
      (installScript "wallpaper-cache.sh")
      (installScript "wallpaper-automation.sh")
      (installScript "fetch-wallpapers.sh")
      (installScript "wallpaper-set.sh")
      (installScript "wallpaper-list.sh")
      (installScript "wallpaper-random.sh")

      # Only real writable directories (never under Nix store symlinks)
      {
        ".config/wallpapers/.keep".text = "";
        ".cache/hyprlock-assets/.keep".text = "";
      }
    ];

    ############################
    # Seed writable settings (replace Nix-store symlinks if present)
    ############################
    home.activation.wallpaperSettingsSeed = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      S="$HOME/.config/hypr/settings"
      mkdir -p "$S"

      seed_file() {
        local path="$1" default="$2"
        # If a symlink (e.g. to Nix store), remove it and replace with a real file
        if [ -L "$path" ]; then
          rm -f "$path"
        fi
        # Create only if missing
        if [ ! -f "$path" ]; then
          printf "%s\n" "$default" > "$path"
          chmod 0644 "$path"
        fi
      }

      seed_file "$S/wallpaper-effect.sh" "off"
      seed_file "$S/blur.sh" "50x30"
      seed_file "$S/wallpaper-automation.sh" "300"
      # Presence of this file enables caching in wallpaper.sh
      if [ ! -e "$S/wallpaper_cache" ]; then
        : > "$S/wallpaper_cache"
        chmod 0644 "$S/wallpaper_cache"
      fi
    '';

    ############################
    # Seed wallpapers once if empty (non-blocking)
    # If empty, *defer* actual fetch to the user service to avoid blocking HM.
    ############################
    home.activation.wallpapersSeed = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      WALLS="$HOME/.config/wallpapers"
      if [ -z "$(find "$WALLS" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -n1)" ]; then
        echo ":: No wallpapers found; deferring fetch to user service"
        systemctl --user start waypaper-fetch.service || true
      fi
    '';

    ############################
    # Restore last wallpaper on session start — via generator (effect + theming)
    # Small delay + timeout so it never blocks HM or session startup.
    ############################
    systemd.user.services."waypaper-restore" = {
      Unit = {
        Description = "Restore last wallpaper via wallpaper.sh (effect-aware)";
        After = ["hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 1"; # wait a bit for Wayland/monitors
        ExecStart = "${config.home.homeDirectory}/.local/bin/wallpaper.sh";
        TimeoutStartSec = "20s";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    ############################
    # Random rotation service — via random script (calls wallpaper.sh)
    # Short timeout to avoid blocking on slow operations.
    ############################
    systemd.user.services."waypaper-random" = {
      Unit = {
        Description = "Set a random wallpaper (effect-aware)";
        After = ["hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${config.home.homeDirectory}/.local/bin/wallpaper-random.sh";
        TimeoutStartSec = "20s";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    ############################
    # Random rotation timer (conditional)
    ############################
    systemd.user.timers."waypaper-random" = lib.mkIf config.hyprland.wallpaper.random.enable {
      Unit = {Description = "Random wallpaper timer";};
      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "${toString config.hyprland.wallpaper.random.intervalSeconds}s";
        Unit = "waypaper-random.service";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    ############################
    # Periodic fetch via systemd timer (conditional)
    ############################
    systemd.user.services."waypaper-fetch" = {
      Unit = {
        Description = "Fetch wallpapers from remote repo";
        After = ["hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${config.home.homeDirectory}/.local/bin/fetch-wallpapers.sh";
        SuccessExitStatus = "0";
        # Make fetch nice/idle and bounded so it never stalls HM
        Nice = 19;
        IOSchedulingClass = "idle";
        TimeoutStartSec = "30s";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    systemd.user.timers."waypaper-fetch" = lib.mkIf config.hyprland.wallpaper.fetch.enable {
      Unit = {Description = "Periodic wallpaper fetch";};
      Timer = {
        OnCalendar = config.hyprland.wallpaper.fetch.onCalendar;
        Persistent = true;
        Unit = "waypaper-fetch.service";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    ############################
    # PATH
    ############################
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

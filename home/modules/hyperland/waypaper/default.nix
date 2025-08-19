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
  # Import the fetcher script
  imports = [
    ./fetcher.nix
  ];

  options = {
    hyprland.wallpaper.enable =
      lib.mkEnableOption "Enable Hyprland wallpaper tools (Waypaper + helpers)";

    # Random rotation
    hyprland.wallpaper.random.enable =
      lib.mkEnableOption "Rotate wallpapers randomly via a systemd timer";
    hyprland.wallpaper.random.intervalSeconds = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Interval (seconds) for the random wallpaper timer.";
    };

    # (Optional) Keep these if you want fetch schedule to be configurable here.
    hyprland.wallpaper.fetch.enable = lib.mkEnableOption "Enable periodic wallpaper fetching (handled centrally)";
    hyprland.wallpaper.fetch.onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "systemd OnCalendar schedule used by the central fetcher.";
    };
  };

  config = lib.mkIf config.hyprland.wallpaper.enable {
    # Do NOT auto-start user units during rebuild (avoid blocking)
    systemd.user.startServices = false;

    # Packages for wallpaper operations
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

    # Scripts -> ~/.local/bin (NOTE: fetch-wallpapers.sh removed; central module provides it)
    home.file = lib.mkMerge [
      (installScript "wallpaper.sh")
      (installScript "wallpaper-restore.sh")
      (installScript "wallpaper-effects.sh")
      (installScript "wallpaper-cache.sh")
      (installScript "wallpaper-automation.sh")
      # (installScript "fetch-wallpapers.sh")  # ← Removed: central fetcher owns it
      (installScript "wallpaper-set.sh")
      (installScript "wallpaper-list.sh")
      (installScript "wallpaper-random.sh")
      (installScript "wallpaper-pick.sh")

      # Writable dirs (never under Nix store symlinks)
      {
        ".config/wallpapers/.keep".text = "";
        ".cache/hyprlock-assets/.keep".text = "";
      }
    ];

    # Seed writable settings
    home.activation.wallpaperSettingsSeed = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      S="$HOME/.config/hypr/settings"
      mkdir -p "$S"

      seed_file() {
        local path="$1" default="$2"
        if [ -L "$path" ]; then
          rm -f "$path"
        fi
        if [ ! -f "$path" ]; then
          printf "%s\n" "$default" > "$path"
          chmod 0644 "$path"
        fi
      }

      seed_file "$S/wallpaper-effect.sh" "off"
      seed_file "$S/blur.sh" "50x30"
      seed_file "$S/wallpaper-automation.sh" "300"

      if [ ! -e "$S/wallpaper_cache" ]; then
        : > "$S/wallpaper_cache"
        chmod 0644 "$S/wallpaper_cache"
      fi
    '';

    # Initial seed: defer to central fetcher if empty
    home.activation.wallpapersSeed = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      WALLS="$HOME/.config/wallpapers"
      if [ -z "$(find "$WALLS" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -n1)" ]; then
        echo ":: No wallpapers found; deferring to central fetcher"
        systemctl --user start waypaper-fetch.service || true
      fi
    '';

    # hyprpaper daemon
    systemd.user.services."hyprpaper" = {
      Unit = {
        Description = "Hyprland wallpaper daemon (hyprpaper)";
        After = ["hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper";
        Restart = "always";
        RestartSec = "200ms";
        TimeoutStartSec = "15s";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    # Restore last wallpaper on session start
    systemd.user.services."waypaper-restore" = {
      Unit = {
        Description = "Restore last wallpaper via wallpaper.sh (effect-aware)";
        After = ["hyprland-env.service" "hyprpaper.service"];
        Requires = ["hyprpaper.service"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2"; # a tiny bit more time
        ExecStart = "${config.home.homeDirectory}/.local/bin/wallpaper.sh";
        TimeoutStartSec = "30s";
        # Treat 'no previous wallpaper' or similar as OK:
        SuccessExitStatus = "0 1";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    # Random rotation (service + timer)
    systemd.user.services."waypaper-random" = {
      Unit = {
        Description = "Set a random wallpaper (effect-aware)";
        After = ["hyprland-env.service" "hyprpaper.service"];
        Requires = ["hyprpaper.service"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${config.home.homeDirectory}/.local/bin/wallpaper-random.sh";
        TimeoutStartSec = "20s";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    systemd.user.timers."waypaper-random" = lib.mkIf config.hyprland.wallpaper.random.enable {
      Unit = {Description = "Random wallpaper timer";};
      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "${toString config.hyprland.wallpaper.random.intervalSeconds}s";
        Unit = "waypaper-random.service";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    # Ensure ~/.local/bin is in PATH
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

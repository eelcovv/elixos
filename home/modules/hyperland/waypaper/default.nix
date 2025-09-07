{
  config,
  pkgs,
  lib,
  ...
}: let
  # Directory containing helper scripts to install into ~/.local/bin
  scriptsDir = ./scripts;

  # Helper to install a script from ./scripts/<name> into ~/.local/bin/<name>
  installScript = name: {
    ".local/bin/${name}" = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };
in {
  imports = [
    ./fetcher.nix
  ];

  ################
  # Options
  ################
  options = {
    hyprland = {
      wallpaper = {
        # Toggle the whole Waypaper/Hypr helpers module (handy to disable on servers)
        enable = lib.mkEnableOption "Enable Hyprland wallpaper tools (Waypaper + helpers)";

        random = {
          enable = lib.mkEnableOption "Rotate wallpapers randomly via a systemd timer";
          intervalSeconds = lib.mkOption {
            type = lib.types.int;
            default = 3600;
            description = "Interval (seconds) for the random wallpaper timer.";
          };
        };

        fetch = {
          enable = lib.mkEnableOption "Enable periodic wallpaper fetching (handled centrally)";
          onCalendar = lib.mkOption {
            type = lib.types.str;
            default = "weekly";
            description = "systemd OnCalendar schedule used by the central fetcher.";
          };
        };
      };
    };
  };

  ################
  # Config
  ################
  config = lib.mkIf config.hyprland.wallpaper.enable {
    # Don't autostart user units during rebuild (keeps HM switch snappy & non-blocking)
    systemd.user.startServices = false;

    # Runtime tools used by your wallpaper helpers (safe even if not all are used)
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

    # Install helper scripts into ~/.local/bin
    home.file = lib.mkMerge [
      (installScript "wallpaper.sh")
      (installScript "wallpaper-restore.sh")
      (installScript "wallpaper-effects.sh")
      (installScript "wallpaper-cache.sh")
      (installScript "wallpaper-automation.sh")
      (installScript "wallpaper-set.sh")
      (installScript "wallpaper-list.sh")
      (installScript "wallpaper-random.sh")
      (installScript "wallpaper-pick.sh")
      {
        ".config/wallpapers/.keep".text = "";
        ".cache/hyprlock-assets/.keep".text = "";
      }
    ];

    # Declaratief, uitvoerbaar placeholder-effectscript (no-op) zodat guards nooit falen
    xdg.configFile."hypr/settings/wallpaper-effect.sh" = {
      text = ''
        #!/usr/bin/env sh
        # Hyprland wallpaper effect placeholder; disabled on this host.
        # This script intentionally does nothing and exits 0.
        exit 0
      '';
      mode = "0755";
    };

    # Seed writable settings used by your scripts (alleen aanmaken als ze nog niet bestaan).
    # Let op: deze blijven mutabel (geen symlinks naar de store) en kunnen later door jou/scrips overschreven worden.
    home.activation.wallpaperSettingsSeed = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      S="$HOME/.config/hypr/settings"
      mkdir -p "$S"

      # Generic seeding helper for plain files (only create when missing)
      seed_file() {
        path="$1"; default="$2"; mode="''${3:-0644}"
        if [ -L "$path" ]; then rm -f "$path"; fi
        if [ ! -f "$path" ]; then
          printf "%s\n" "$default" >"$path"
          chmod "$mode" "$path"
        fi
      }

      # Let op: geen aanmaak/chmod van $S/wallpaper-effect.sh hier; die is declaratief geregeld.

      # Andere seed settings blijven reguliere tekstbestanden
      seed_file "$S/blur.sh" "50x30" 0644
      seed_file "$S/wallpaper-automation.sh" "300" 0644

      if [ ! -e "$S/wallpaper_cache" ]; then
        : > "$S/wallpaper_cache"
        chmod 0644 "$S/wallpaper_cache"
      fi
    '';

    # If no wallpapers exist yet, ask the central fetcher to populate (non-fatal if missing)
    home.activation.wallpapersSeed = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      WALLS="$HOME/.config/wallpapers"
      if ! find "$WALLS" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -n1 | grep -q .; then
        echo ":: No wallpapers found; deferring to central fetcher"
        systemctl --user start waypaper-fetch.service || true
      fi
    '';

    # Guard: voer het effectscript alleen uit als het bestaat én uitvoerbaar is
    home.activation.ensureWallpaperEffectGuard = lib.hm.dag.entryAfter ["writeBoundary"] ''
      S="$HOME/.config/hypr/settings/wallpaper-effect.sh"
      if [ -x "$S" ]; then
        "$S" || true
      fi
    '';

    # Ensure ~/.local/bin is in PATH for the installed helper scripts
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];

    ###############################
    # NEW: random at login + rotate
    ###############################

    # Set a random wallpaper once at session start (after hyprpaper is up)
    systemd.user.services."wallpaper-initial-random" = {
      Unit = {
        Description = "Set a random wallpaper at session start";
        After = ["hyprpaper.service" "hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
        Requires = ["hyprpaper.service"];
        ConditionPathExistsGlob = "%t/hypr/*";
      };
      Service = {
        Type = "oneshot";
        Environment = [
          "WALLPAPER_DIR=%h/.config/wallpapers"
          "QUIET=1"
        ];
        ExecStart = "%h/.local/bin/wallpaper-random.sh";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    # Rotate wallpaper periodically (defaults to every 30 minutes below)
    systemd.user.services."wallpaper-rotate" = {
      Unit = {
        Description = "Rotate wallpaper periodically";
        PartOf = ["hyprland-session.target"];
        After = ["hyprpaper.service"];
      };
      Service = {
        Type = "oneshot";
        Environment = [
          "WALLPAPER_DIR=%h/.config/wallpapers"
          "QUIET=1"
        ];
        ExecStart = "%h/.local/bin/wallpaper-random.sh";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    systemd.user.timers."wallpaper-rotate" = {
      Unit = {Description = "Timer for wallpaper rotation";};
      Timer = {
        # Kick once shortly after login, then repeat every 30 minutes.
        OnBootSec = "1m";
        OnUnitActiveSec = "30m";
        Unit = "wallpaper-rotate.service";
        AccuracySec = "30s";
      };
      Install = {WantedBy = ["timers.target" "hyprland-session.target"];};
    };
  };
}

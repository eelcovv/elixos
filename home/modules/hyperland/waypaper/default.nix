# English comments inside the code block
{
  config,
  pkgs,
  lib,
  ...
}: let
  scriptsDir = ./scripts;

  # Helper to install scripts from ./scripts/<name> into ~/.local/bin/<name>
  installScript = name: {
    ".local/bin/${name}" = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };

  # Convenience: glob that matches common wallpaper types (both lowercase & uppercase)
  wallpaperGlob = "%h/.config/wallpapers/*.{png,jpg,jpeg,webp,PNG,JPG,JPEG,WEBP}";
in {
  imports = [./fetcher.nix];

  options = {
    hyprland.wallpaper.enable = lib.mkEnableOption "Enable Hyprland wallpaper tools (Waypaper + helpers)";
    hyprland.wallpaper.random.enable = lib.mkEnableOption "Rotate wallpapers randomly via a systemd timer";
    hyprland.wallpaper.random.intervalSeconds = lib.mkOption {
      type = lib.types.int;
      default = 3600;
      description = "Interval (seconds) for the random wallpaper timer.";
    };
    hyprland.wallpaper.fetch.enable = lib.mkEnableOption "Enable periodic wallpaper fetching (handled centrally)";
    hyprland.wallpaper.fetch.onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "systemd OnCalendar schedule used by the central fetcher.";
    };
  };

  config = lib.mkIf config.hyprland.wallpaper.enable {
    # Avoid starting/restarting user services during HM switch (keeps activation snappy)
    systemd.user.startServices = false;

    home.packages =
      (with pkgs; [
        waypaper
        hyprpaper
        imagemagick
        wallust
        matugen
        libnotify
        swaynotificationcenter
        git
        nwg-dock-hyprland
      ])
      ++ lib.optionals (pkgs ? pywalfox) [pkgs.pywalfox];

    # Helper scripts
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

    # English comments inside the code block
    home.activation.ensureEffectConf = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -euo pipefail
      CONF="$HOME/.config/hypr/settings/effect.conf"
      if [ ! -e "$CONF" ]; then
        mkdir -p "$(dirname "$CONF")"
        echo off > "$CONF"
        chmod 0644 "$CONF"
      fi
    '';

    xdg.configFile."hypr/settings/blur.sh".text = "50x30\n";
    xdg.configFile."hypr/settings/wallpaper-automation.sh".text = "300\n";

    # Create runtime cache file
    home.activation.ensureWallpaperCache = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      S="$HOME/.config/hypr/settings"
      mkdir -p "$S"
      [ -e "$S/wallpaper_cache" ] || : > "$S/wallpaper_cache"
      chmod 0644 "$S/wallpaper_cache"
    '';

    # Remove the old "ensureWallpaperEffectGuard" hook; not needed anymore.

    # Initial random at session start; avoid hard PartOf=hyprland-session.target to prevent cycles
    systemd.user.services."wallpaper-initial-random" = {
      Unit = {
        Description = "Set a random wallpaper at session start";
        After = ["graphical-session.target" "hyprpaper.service"];
        Wants = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        Environment = [
          "WALLPAPER_DIR=%h/.config/wallpapers"
          "QUIET=1"
        ];
        ExecStart = "/bin/sh -lc '%h/.local/bin/wallpaper-random.sh || true'";
      };
      Install.WantedBy = ["default.target"];
    };

    # Periodic rotation; no PartOf, no Conditions (we guard inside the script)
    systemd.user.services."wallpaper-rotate" = {
      Unit = {
        Description = "Rotate wallpaper periodically";
        After = ["graphical-session.target" "hyprpaper.service"];
        Wants = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        Environment = [
          "WALLPAPER_DIR=%h/.config/wallpapers"
          "QUIET=1"
        ];
        ExecStart = "/bin/sh -lc '%h/.local/bin/wallpaper-random.sh || true'";
      };
      Install.WantedBy = ["default.target"];
    };

    # Timer only under timers.target (avoid tying it to hyprland targets → less cycles)
    systemd.user.timers."wallpaper-rotate" = {
      Unit.Description = "Timer for wallpaper rotation";
      Timer = {
        OnBootSec = "1m";
        OnUnitActiveSec = "${toString config.hyprland.wallpaper.random.intervalSeconds}s";
        Unit = "wallpaper-rotate.service";
        AccuracySec = "30s";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };

    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

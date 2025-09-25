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
    hyprland.wallpaper = {
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

  config = lib.mkIf config.hyprland.wallpaper.enable {
    # Avoid starting/restarting user services during HM switch (keeps activation snappy)
    systemd.user.startServices = false;

    # Runtime tools used by your wallpaper helpers
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

    # 1) Install helper scripts into ~/.local/bin (executable)
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

    # 2) Deliver settings declaratively (no seeding-by-running)
    #    - wallpaper-effect.sh: safe no-op placeholder, executable
    #    - blur.sh / wallpaper-automation.sh: plain text config (non-exec)
    xdg.configFile."hypr/settings/wallpaper-effect.sh" = {
      text = ''
        #!/usr/bin/env sh
        # Hyprland wallpaper effect placeholder; intentionally a no-op.
        exit 0
      '';
      executable = true;
    };

    xdg.configFile."hypr/settings/blur.sh".text = "50x30\n";
    xdg.configFile."hypr/settings/wallpaper-automation.sh".text = "300\n";

    # 3) Create cache file if missing (runtime file; do not manage declaratively)
    home.activation.ensureWallpaperCache = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      S="$HOME/.config/hypr/settings"
      mkdir -p "$S"
      if [ ! -e "$S/wallpaper_cache" ]; then
        : > "$S/wallpaper_cache"
        chmod 0644 "$S/wallpaper_cache"
      fi
    '';

    # 4) Optional: call effect script only if present and executable (non-fatal)
    home.activation.ensureWallpaperEffectGuard = lib.hm.dag.entryAfter ["linkGeneration"] ''
      S="$HOME/.config/hypr/settings/wallpaper-effect.sh"
      if [ -x "$S" ]; then
        "$S" || true
      fi
    '';

    # 5) Set a random wallpaper once at session start (guarded; non-fatal)
    systemd.user.services."wallpaper-initial-random" = {
      Unit = {
        Description = "Set a random wallpaper at session start";
        After = ["hyprpaper.service" "hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
        Requires = ["hyprpaper.service"];

        # One executable check, multiple path-exists globs
        ConditionPathIsExecutable = "%h/.local/bin/wallpaper-random.sh";
        ConditionPathExistsGlob = [
          wallpaperGlob # %h/.config/wallpapers/*.{png,jpg,jpeg,webp,...}
          "%t/hypr/*" # Hyprland runtime socket present
        ];
      };
      Service = {
        Type = "oneshot";
        Environment = [
          "WALLPAPER_DIR=%h/.config/wallpapers"
          "QUIET=1"
        ];
        ExecStart = "/bin/sh -lc '%h/.local/bin/wallpaper-random.sh || true'";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # 6) Periodic rotation (guarded; non-fatal)
    systemd.user.services."wallpaper-rotate" = {
      Unit = {
        Description = "Rotate wallpaper periodically";
        PartOf = ["hyprland-session.target"];
        After = ["hyprpaper.service"];

        ConditionPathIsExecutable = "%h/.local/bin/wallpaper-random.sh";
        ConditionPathExistsGlob = [
          wallpaperGlob
          "%t/hypr/*"
        ];
      };
      Service = {
        Type = "oneshot";
        Environment = [
          "WALLPAPER_DIR=%h/.config/wallpapers"
          "QUIET=1"
        ];
        ExecStart = "/bin/sh -lc '%h/.local/bin/wallpaper-random.sh || true'";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # 7) Timer uses your option (random.intervalSeconds)
    systemd.user.timers."wallpaper-rotate" = {
      Unit.Description = "Timer for wallpaper rotation";
      Timer = {
        OnBootSec = "1m";
        OnUnitActiveSec = "${toString config.hyprland.wallpaper.random.intervalSeconds}s";
        Unit = "wallpaper-rotate.service";
        AccuracySec = "30s";
      };
      Install.WantedBy = ["timers.target" "hyprland-session.target"];
    };

    # Make sure ~/.local/bin is in PATH for your helper scripts
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

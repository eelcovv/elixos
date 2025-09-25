{
  config,
  pkgs,
  lib,
  ...
}: let
  scriptsDir = ./scripts;

  installScript = name: {
    ".local/bin/${name}" = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };
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
    systemd.user.startServices = false;

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

    # 1) Helper-scripts naar ~/.local/bin (blijft zoals je had)
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

    # 2) **Declaratief** leveren van settings-bestanden (ipv seeden/runnen)
    #    - wallpaper-effect.sh: een no-op placeholder, executable (veilig om aan te roepen)
    #    - blur.sh / wallpaper-automation.sh: plaintext settings (geen exec)
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

    # 3) Maak een lege cachefile **alleen als hij nog niet bestaat**
    home.activation.ensureWallpaperCache = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      S="$HOME/.config/hypr/settings"
      mkdir -p "$S"
      if [ ! -e "$S/wallpaper_cache" ]; then
        : > "$S/wallpaper_cache"
        chmod 0644 "$S/wallpaper_cache"
      fi
    '';

    # 4) (optioneel) Guard die het effect-script alleen draait als het executable is
    home.activation.ensureWallpaperEffectGuard = lib.hm.dag.entryAfter ["linkGeneration"] ''
      S="$HOME/.config/hypr/settings/wallpaper-effect.sh"
      if [ -x "$S" ]; then
        "$S" || true
      fi
    '';

    # 5) Random bij login + rotate timer (zoals je had)
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
        Environment = ["WALLPAPER_DIR=%h/.config/wallpapers" "QUIET=1"];
        ExecStart = "%h/.local/bin/wallpaper-random.sh";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    systemd.user.services."wallpaper-rotate" = {
      Unit = {
        Description = "Rotate wallpaper periodically";
        PartOf = ["hyprland-session.target"];
        After = ["hyprpaper.service"];
      };
      Service = {
        Type = "oneshot";
        Environment = ["WALLPAPER_DIR=%h/.config/wallpapers" "QUIET=1"];
        ExecStart = "%h/.local/bin/wallpaper-random.sh";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    systemd.user.timers."wallpaper-rotate" = {
      Unit.Description = "Timer for wallpaper rotation";
      Timer = {
        OnBootSec = "1m";
        OnUnitActiveSec = "30m";
        Unit = "wallpaper-rotate.service";
        AccuracySec = "30s";
      };
      Install.WantedBy = ["timers.target" "hyprland-session.target"];
    };
  };
}

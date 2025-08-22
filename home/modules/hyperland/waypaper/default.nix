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
  imports = [
    ./fetcher.nix
  ];

  ################
  # Options
  ################
  options = {
    hyprland = {
      wallpaper = {
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
    # Do NOT auto-start user units during rebuild (avoid blocking UI during HM switch)
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

    # Seed writable settings (kept for your scripts; harmless if unused)
    home.activation.wallpaperSettingsSeed = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      S="$HOME/.config/hypr/settings"
      mkdir -p "$S"

      seed_file() {
        local path="$1" default="$2"
        if [ -L "$path" ]; then rm -f "$path"; fi
        if [ ! -f "$path" ]; then
          printf "%s\n" "$default" >"$path"
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

    # If no wallpapers exist, kick the central fetcher once (non-fatal if absent)
    home.activation.wallpapersSeed = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      WALLS="$HOME/.config/wallpapers"
      if [ -z "$(find "$WALLS" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -n1)" ]; then
        echo ":: No wallpapers found; deferring to central fetcher"
        systemctl --user start waypaper-fetch.service || true
      fi
    '';

    # IMPORTANT:
    # Do NOT define or start wallpaper services here.
    # Hyprpaper is managed centrally in the Hyprland module to avoid duplicates.
    # If you ever want to reintroduce a timer, do it via hyprpaper IPC only,
    # and ensure it 'After=hyprland-session.target' with proper env.

    # Keep ~/.local/bin in PATH
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

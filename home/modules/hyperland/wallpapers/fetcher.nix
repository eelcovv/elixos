{
  config,
  pkgs,
  lib,
  ...
}: let
  # Runtime target directory for wallpapers
  wpDir = "${config.xdg.configHome}/wallpapers";

  # Build the fetch script as a Nix binary (single source of truth).
  # The script content comes from ./scripts/fetch-wallpapers.sh in your repo.
  fetcherBin = pkgs.writeShellApplication {
    name = "fetch-wallpapers";
    runtimeInputs = [pkgs.git pkgs.rsync pkgs.coreutils];
    text = builtins.readFile ./scripts/fetch-wallpapers.sh;
  };
in {
  ##########################################################################
  # Central owner of the waypaper-fetch.{service,timer}
  ##########################################################################

  # Make the binary available in PATH (can be run as "fetch-wallpapers")
  home.packages = [fetcherBin];

  # Also install a wrapper under ~/.local/bin for muscle memory:
  # "fetch-wallpapers.sh" will just call the Nix-packaged binary.
  home.file.".local/bin/fetch-wallpapers.sh" = {
    text = ''
      #!/usr/bin/env bash
      exec ${lib.getExe fetcherBin} "$@"
    '';
    executable = true;
  };

  # One-shot service to fetch wallpapers (runs on demand or at login)
  systemd.user.services."waypaper-fetch" = {
    Unit = {
      Description = "Fetch wallpapers (central, repo script)";
      After = ["hyprland-env.service" "network-online.target"];
      Wants = ["network-online.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe fetcherBin; # Always use the Nix binary here
      TimeoutStartSec = "3min";
      Environment = [
        "XDG_CONFIG_HOME=%h/.config"
        "HOME=%h"
        "WALLPAPER_DIR=${wpDir}"
      ];
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    Install = {WantedBy = ["hyprland-session.target"];};
  };

  # Periodic fetch timer (optional, controlled by waypaper module options)
  systemd.user.timers."waypaper-fetch" = lib.mkIf (config ? hyprland.wallpaper.fetch && (config.hyprland.wallpaper.fetch.enable or false)) {
    Unit = {Description = "Periodic wallpaper fetch (central)";};
    Timer = {
      OnCalendar = config.hyprland.wallpaper.fetch.onCalendar or "weekly";
      Persistent = true;
      Unit = "waypaper-fetch.service";
    };
    Install = {WantedBy = ["timers.target"];};
  };

  # Seed hook: if no wallpapers are present yet, trigger a non-blocking fetch
  home.activation.wallpapersSeedCentral = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    WALLS="$HOME/.config/wallpapers"
    if [ -z "$(find "$WALLS" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -n1)" ]; then
      echo ":: No wallpapers found; starting waypaper-fetch.service"
      systemctl --user start waypaper-fetch.service || true
    fi
  '';
}

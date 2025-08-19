{
  config,
  pkgs,
  lib,
  ...
}: let
  # Runtime target for wallpapers
  wpDir = "${config.xdg.configHome}/wallpapers";

  # Reuse your existing script content exactly as-is (single source of truth).
  # This packs ./scripts/fetch-wallpapers.sh into a Nix-provided binary.
  # Adjust the path below if this fetcher.nix is not in the same tree layout.
  fetcherBin = pkgs.writeShellApplication {
    name = "fetch-wallpapers";
    runtimeInputs = [pkgs.git pkgs.rsync pkgs.coreutils];
    text = builtins.readFile ./scripts/fetch-wallpapers.sh;
  };
in {
  ##########################################################################
  # Central owner of the "waypaper-fetch" service & timer.
  # Waybar/Waypaper modules should NOT define a conflicting unit.
  ##########################################################################

  # Ensure the command is available to the user (so manual runs work too)
  home.packages = [fetcherBin];

  # One-shot fetch service (can be started on demand or by timers/activation)
  systemd.user.services."waypaper-fetch" = {
    Unit = {
      Description = "Fetch wallpapers (central, uses repo script)";
      After = ["hyprland-env.service" "network-online.target"];
      Wants = ["network-online.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "oneshot";
      # Use the packaged binary (same content as your script)
      ExecStart = lib.getExe fetcherBin;
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

  # Periodic fetch: schedule comes from waypaper options if you use those,
  # otherwise you can hardcode here. Keep it conditional:
  systemd.user.timers."waypaper-fetch" = lib.mkIf (config ? hyprland.wallpaper.fetch && config.hyprland.wallpaper.fetch.enable or false) {
    Unit = {Description = "Periodic wallpaper fetch (central)";};
    Timer = {
      OnCalendar = config.hyprland.wallpaper.fetch.onCalendar or "weekly";
      Persistent = true;
      Unit = "waypaper-fetch.service";
    };
    Install = {WantedBy = ["timers.target"];};
  };

  # Seed: if no images exist yet, trigger a non-blocking initial fetch
  home.activation.wallpapersSeedCentral = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    WALLS="$HOME/.config/wallpapers"
    if [ -z "$(find "$WALLS" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -n1)" ]; then
      echo ":: No wallpapers found; starting waypaper-fetch.service"
      systemctl --user start waypaper-fetch.service || true
    fi
  '';
}

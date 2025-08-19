{
  config,
  pkgs,
  lib,
  ...
}: let
  # Where wallpapers are stored at runtime
  wpDir = "${config.xdg.configHome}/wallpapers";

  # Remote repository & branch
  wpRepoUrl = "https://github.com/mylinuxforwork/wallpaper";
  wpRepoBranch = "main";

  # Build a self-contained fetch script as a Nix derivation
  fetchScript = pkgs.writeShellScript "fetch-wallpapers.sh" ''
    set -euo pipefail
    echo "📥 Downloading wallpapers from ${wpRepoUrl} ..."
    export GIT_TERMINAL_PROMPT=0
    export GIT_ASKPASS=true

    if [ -d "${wpDir}/.git" ]; then
      ${pkgs.git}/bin/git -C "${wpDir}" remote set-url origin "${wpRepoUrl}" || true
      ${pkgs.git}/bin/git -C "${wpDir}" fetch --depth=1 origin "${wpRepoBranch}"
      ${pkgs.git}/bin/git -C "${wpDir}" reset --hard FETCH_HEAD
      ${pkgs.git}/bin/git -C "${wpDir}" clean -fdx
    else
      ${pkgs.coreutils}/bin/mkdir -p "${wpDir}"
      tmp="$(${pkgs.coreutils}/bin/mktemp -d)"
      trap '${pkgs.coreutils}/bin/rm -rf "$tmp"' EXIT
      ${pkgs.git}/bin/git clone --depth 1 --branch "${wpRepoBranch}" "${wpRepoUrl}" "$tmp/repo"
      ${pkgs.rsync}/bin/rsync -a --delete "$tmp/repo/" "${wpDir}/"
    fi

    echo "✅ Wallpapers updated in ${wpDir}"
  '';
in {
  ##########################################################################
  # This module owns the "waypaper-fetch" service & timer, centrally.
  # It intentionally does NOT ship any Waybar/Waypaper bits. Those modules
  # should not define services/timers with the same name.
  ##########################################################################

  # Tools needed by the script; keep git/rsync available at runtime
  home.packages = with pkgs; [git rsync];

  # On-demand fetch (e.g., started at session begin or manually)
  systemd.user.services."waypaper-fetch" = {
    Unit = {
      Description = "Fetch wallpapers from remote repo (central)";
      After = ["hyprland-env.service" "network-online.target"];
      Wants = ["network-online.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = fetchScript;
      TimeoutStartSec = "3min";
      Environment = [
        "XDG_CONFIG_HOME=%h/.config"
        "HOME=%h"
      ];
      # Keep this lightweight; do not block session startup
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    Install = {WantedBy = ["hyprland-session.target"];};
  };

  # Periodic fetch, controlled by waypaper's existing options
  systemd.user.timers."waypaper-fetch" = lib.mkIf config.hyprland.wallpaper.fetch.enable {
    Unit = {Description = "Periodic wallpaper fetch (central)";};
    Timer = {
      OnCalendar = config.hyprland.wallpaper.fetch.onCalendar;
      Persistent = true;
      Unit = "waypaper-fetch.service";
    };
    Install = {WantedBy = ["timers.target"];};
  };

  # Seed: if folder has no images, trigger a fetch (non-blocking)
  home.activation.wallpapersSeedCentral = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    WALLS="$HOME/.config/wallpapers"
    if [ -z "$(find "$WALLS" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -n1)" ]; then
      echo ":: No wallpapers found; deferring fetch to user service"
      systemctl --user start waypaper-fetch.service || true
    fi
  '';
}

{
  config,
  pkgs,
  lib,
  ...
}: let
  # Runtime target directory for wallpapers (override via $WALLPAPER_DIR if desired)
  wpDir = "${config.xdg.configHome}/wallpapers";

  # Build a robust fetcher as a single Nix-packaged binary.
  # Notes:
  # - Shallow clone (depth=1), no prompts.
  # - Copies *.png/jpg/jpeg/webp into $WALLPAPER_DIR.
  # - Cleans up temp dir on exit.
  fetcherBin = pkgs.writeShellApplication {
    name = "fetch-wallpapers";
    runtimeInputs = [pkgs.git pkgs.coreutils pkgs.findutils];
    text = ''
      #!/usr/bin/env bash
      # Fetch wallpapers into ~/.config/wallpapers (or $WALLPAPER_DIR)
      # Env overrides:
      #   REPO_URL      (default: https://github.com/mylinuxforwork/wallpaper)
      #   REPO_BRANCH   (default: main)
      #   WALLPAPER_DIR (default: ${wpDir})
      set -euo pipefail

      REPO_URL="''${REPO_URL:-https://github.com/mylinuxforwork/wallpaper}"
      REPO_BRANCH="''${REPO_BRANCH:-main}"
      WALLPAPER_DIR="''${WALLPAPER_DIR:-${wpDir}}"

      export GIT_TERMINAL_PROMPT=0
      export GIT_ASKPASS=true

      echo "📥 Downloading wallpapers from $REPO_URL (branch=$REPO_BRANCH) …"
      tmp="$(mktemp -d)"
      trap 'rm -rf "$tmp"' EXIT

      # Shallow clone
      if ! git clone --depth=1 --branch "$REPO_BRANCH" -- "$REPO_URL" "$tmp/repo"; then
        echo "WARN: git clone failed; network/repo issue?" >&2
        exit 2
      fi

      mkdir -p -- "$WALLPAPER_DIR"

      # Copy supported formats into target
      shopt -s nullglob dotglob
      found_files=0
      while IFS= read -r -d "" f; do
        cp -f -- "$f" "$WALLPAPER_DIR/"
        found_files=1
      done < <(find "$tmp/repo" -type f \
                  \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \
                  -print0)

      if [[ "$found_files" -eq 0 ]]; then
        echo "WARN: no image files found in repo; nothing copied." >&2
        # Non-fatal; still succeed to avoid degrading the session.
        exit 0
      fi

      echo "✅ Wallpapers updated in $WALLPAPER_DIR"
    '';
  };
in {
  ##########################################################################
  # Central owner of waypaper-fetch.{service,timer}
  ##########################################################################

  # Provide the binary in PATH (run as "fetch-wallpapers")
  home.packages = [fetcherBin];

  # Convenience wrapper for muscle memory: ~/.local/bin/fetch-wallpapers.sh
  home.file.".local/bin/fetch-wallpapers.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Thin wrapper to the Nix-packaged fetcher
      exec ${lib.getExe fetcherBin} "$@"
    '';
    executable = true;
  };

  # One-shot user service to fetch wallpapers (invoked on demand or by timer)
  systemd.user.services."waypaper-fetch" = {
    Unit = {
      Description = "Fetch wallpapers (central, repo script)";
      # In user scope, network-online.target is unreliable; keep it simple.
      After = ["hyprland-env.service"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe fetcherBin;
      TimeoutStartSec = "3min";
      Environment = [
        "XDG_CONFIG_HOME=%h/.config"
        "HOME=%h"
        "WALLPAPER_DIR=${wpDir}"
        "GIT_TERMINAL_PROMPT=0"
        "GIT_ASKPASS=true"
      ];
      # Be lenient on transient failures (no net/repo) so the session is not "degraded".
      SuccessExitStatus = "0 1 2 3 4 128";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    Install = {WantedBy = ["hyprland-session.target"];};
  };

  # Periodic fetch timer (if your waypaper options are present, use those; else weekly)
  systemd.user.timers."waypaper-fetch" = let
    haveOpt = config ? hyprland.wallpaper.fetch;
    enabled = haveOpt && (config.hyprland.wallpaper.fetch.enable or false);
    cal =
      if haveOpt
      then (config.hyprland.wallpaper.fetch.onCalendar or "weekly")
      else "weekly";
  in
    lib.mkIf enabled {
      Unit = {Description = "Periodic wallpaper fetch (central)";};
      Timer = {
        OnCalendar = cal;
        Persistent = true;
        Unit = "waypaper-fetch.service";
      };
      Install = {WantedBy = ["timers.target"];};
    };

  # Seed hook: if no wallpapers exist yet, trigger a non-blocking fetch once
  home.activation.wallpapersSeedCentral = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    WALLS="$HOME/.config/wallpapers"
    if [ -z "$(find "$WALLS" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | head -n1)" ]; then
      echo ":: No wallpapers found; attempting initial fetch (non-blocking)"
      systemctl --user start waypaper-fetch.service || true
    fi
  '';
}

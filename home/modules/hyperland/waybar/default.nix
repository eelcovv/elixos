{
  config,
  pkgs,
  lib,
  ...
}: let
  /*
  Small wait helper so Waybar starts after Hyprland IPC/outputs are ready.
  We keep the wait short to avoid login delays.
  */
  waitForHypr = pkgs.writeShellScript "wait-for-hypr" ''
    # Wait up to ~5s for Hyprland to become queryable
    for i in $(seq 1 50); do
      if ${pkgs.hyprland}/bin/hyprctl -j monitors >/dev/null 2>&1; then
        exit 0
      fi
      sleep 0.1
    done
    # If Hyprland isn't ready, still continue; Waybar can retry internally.
    exit 0
  '';

  /*
  Tiny helper to reload Waybar cleanly from scripts (SIGUSR2), with a fallback to restart.
  Name is distinct from the vendor unit to avoid conflicts: "waybar-managed.service".
  */
  waybarReload = pkgs.writeShellScriptBin "waybar-reload" ''
    set -euo pipefail
    systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service
  '';
in {
  # Ensure Waybar and the reload helper are available in PATH
  home.packages = [
    pkgs.waybar
    waybarReload
  ];

  /*
  IMPORTANT:
  - Remove any Hyprland autostart for Waybar (e.g., `exec-once = waybar`) outside this module.
  - We fully manage a single instance via systemd --user.
  */
  systemd.user.services."waybar-managed" = {
    Unit = {
      Description = "Waybar (managed by Home Manager, independent of graphical-session.target)";
      # Tie to the generic user session target to avoid inactives on some setups
      After = ["default.target"];
      PartOf = ["default.target"];
    };

    Service = {
      Type = "simple";
      # Short guard: wait until Hyprland's IPC answers
      ExecStartPre = "${waitForHypr}";
      ExecStart = "${pkgs.waybar}/bin/waybar";
      # Nice first-class reload (Waybar listens to SIGUSR2)
      ExecReload = "kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      # Use a string value here (not a float) to satisfy HM's type:
      RestartSec = "500ms";
      # Example: make Waybar quieter (uncomment if desired)
      # Environment = "WAYBAR_LOG_LEVEL=warning";
    };

    Install = {
      # Start in the normal user session
      WantedBy = ["default.target"];
    };
  };

  # Ensure ~/.local/bin (or similar) includes the reload helper if you rely on it from scripts
  home.sessionPath = ["$HOME/.local/bin"];
}

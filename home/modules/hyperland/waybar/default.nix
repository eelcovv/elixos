{
  config,
  pkgs,
  lib,
  ...
}: let
  # Paths relative to this module file
  waybarDir = ./.;
  themesDir = ./themes;
  scriptsDir = ./scripts;

  # Resolve to "~/.config/waybar"
  cfgPath = "${config.xdg.configHome}/waybar";

  # Short wait so Hyprland IPC/outputs are ready before starting Waybar
  waitForHypr = pkgs.writeShellScript "wait-for-hypr" ''
    for i in $(seq 1 50); do
      if ${pkgs.hyprland}/bin/hyprctl -j monitors >/dev/null 2>&1; then
        exit 0
      fi
      sleep 0.1
    done
    exit 0
  '';

  # Theme switcher: update ~/.config/waybar/{config,style.css} symlinks then reload Waybar
  waybarSwitch = pkgs.writeShellScriptBin "waybar-switch-theme" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Usage:
    #   waybar-switch-theme THEME [VARIANT]
    #   waybar-switch-theme THEME/VARIANT

    XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-\$HOME/.config}"
    BASE="''${XDG_CONFIG_HOME}/waybar/themes"
    DEF="''${BASE}/default"

    if [[ $# -lt 1 ]]; then
      echo "Usage: \$0 <theme>[/<variant>] [variant]" >&2
      exit 2
    fi

    themeArg="$1"
    variantArg="''${2:-}"

    # Support "theme/variant" or "theme variant"
    theme="''${themeArg%/*}"
    variant="''${themeArg#*/}"
    if [[ "$themeArg" != "$variant" && -n "$variant" && -n "$variantArg" ]]; then
      variant="$variantArg"
    elif [[ "$themeArg" == "$variant" ]]; then
      variant="$variantArg"
    fi

    themeDir="''${BASE}/''${theme}"
    varDir="''${themeDir}/''${variant}"

    choose_file() {
      local rel="$1"
      local cand
      for cand in \
        "''${varDir}/''${rel}" \
        "''${themeDir}/''${rel}" \
        "''${DEF}/''${rel}"
      do
        if [[ -f "''${cand}" ]]; then
          printf '%s\n' "''${cand}"
          return 0
        fi
      done
      return 1
    }

    cfg_src="$(choose_file config.jsonc || true)"
    css_src="$(choose_file style.css || true)"

    if [[ -z "''${cfg_src:-}" || -z "''${css_src:-}" ]]; then
      echo "Theme ''${theme}''${variant:+/''${variant}} is missing config.jsonc or style.css (checked variant/theme/default)." >&2
      exit 1
    fi

    mkdir -p "''${XDG_CONFIG_HOME}/waybar"

    ln -sfn "''${cfg_src}" "''${XDG_CONFIG_HOME}/waybar/config"
    ln -sfn "''${css_src}" "''${XDG_CONFIG_HOME}/waybar/style.css"

    # Reload managed service if present; otherwise fallback to USR2 or restart
    if systemctl --user status waybar-managed.service >/dev/null 2>&1; then
      systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service
    else
      pkill -USR2 -x waybar || { pkill -x waybar || true; nohup waybar >/dev/null 2>&1 & }
    fi

    echo "Waybar theme: Applied: ''${theme}''${variant:+/''${variant}}"
  '';

  # Simple helper to reload (SIGUSR2) with restart fallback
  waybarReload = pkgs.writeShellScriptBin "waybar-reload" ''
    systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service
  '';
in {
  home.packages = [
    pkgs.waybar
    waybarSwitch
    waybarReload
  ];

  # Install the full themes tree under ~/.config/waybar/themes
  xdg.configFile."waybar/themes".source = themesDir;
  xdg.configFile."waybar/themes".recursive = true;

  # One-time helper: if a repo-level modules.jsonc exists, link it on first run (do not overwrite user overrides)
  home.activation.ensureModulesJsonc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
    mkdir -p "''${cfg_dir}"
    if [ ! -e "''${cfg_dir}/modules.jsonc" ] && [ -e "${themesDir}/modules.jsonc" ]; then
      ln -s "${themesDir}/modules.jsonc" "''${cfg_dir}/modules.jsonc"
    fi
  '';

  # First-run symlinks to default theme; switcher will update these later
  home.activation.ensureWaybarSymlinks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
    mkdir -p "''${cfg_dir}"
    [ -e "''${cfg_dir}/config"    ] || ln -s "${themesDir}/default/config.jsonc" "''${cfg_dir}/config"
    [ -e "''${cfg_dir}/style.css" ] || ln -s "${themesDir}/default/style.css"   "''${cfg_dir}/style.css"
  '';

  # Single owner: declarative systemd --user service for Waybar that uses ~/.config/waybar/{config,style.css}
  systemd.user.services."waybar-managed" = {
    Unit = {
      Description = "Waybar (managed by Home Manager; uses ~/.config/waybar/{config,style.css})";
      After = ["default.target"];
      PartOf = ["default.target"];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${waitForHypr}";
      ExecStart = "${pkgs.waybar}/bin/waybar -c ${cfgPath}/config -s ${cfgPath}/style.css";
      ExecReload = "kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = "500ms";
      Environment = [
        "WAYBAR_CONFIG=%h/.config/waybar/config"
        "WAYBAR_STYLE=%h/.config/waybar/style.css"
      ];
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  # Ensure ~/.local/bin (or similar) is on PATH for helper scripts
  home.sessionPath = ["$HOME/.local/bin"];
}

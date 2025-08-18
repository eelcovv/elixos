{ config, pkgs, lib, ... }:
let
  # Paths relative to this module file
  waybarDir  = ./.;
  themesDir  = ./themes;
  scriptsDir = ./scripts;

  # Resolves to "~/.config/waybar"
  cfgPath = "${config.xdg.configHome}/waybar";

  # Small readiness gate: wait until Hyprland IPC responds before launching Waybar
  waitForHypr = pkgs.writeShellScript "wait-for-hypr" ''
    for i in $(seq 1 50); do
      if ${pkgs.hyprland}/bin/hyprctl -j monitors >/dev/null 2>&1; then
        exit 0
      fi
      sleep 0.1
    done
    exit 0
  '';
in {
  config = {
    ##########################################################################
    # Waybar — managed by systemd, tied to the Hyprland user target
    ##########################################################################
    programs.waybar.enable = true;
    programs.waybar.package = pkgs.waybar;
    programs.waybar.systemd.enable = true;
    programs.waybar.systemd.target = "hyprland-session.target";

    ##########################################################################
    # Publish repository themes into ~/.config/waybar/themes (read-only)
    ##########################################################################
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    ##########################################################################
    # Global fallbacks so theme switchers never hit missing files
    ##########################################################################
    xdg.configFile."waybar/modules.jsonc".text = ''{ }'';
    xdg.configFile."waybar/colors.css".text =
      ''/* global fallback; themes usually override this */'';

    ##########################################################################
    # First-run symlinks to a sane default; switcher updates these later
    ##########################################################################
    home.activation.ensureWaybarSymlinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      cfg_dir="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      mkdir -p "$cfg_dir"
      [ -e "$cfg_dir/config"    ] || ln -s "${themesDir}/default/config.jsonc" "$cfg_dir/config"
      [ -e "$cfg_dir/style.css" ] || ln -s "${themesDir}/default/style.css"   "$cfg_dir/style.css"
      # If repository provides a modules.jsonc, link it once (do not overwrite user edits)
      if [ ! -e "$cfg_dir/modules.jsonc" ] && [ -e "${themesDir}/modules.jsonc" ]; then
        ln -s "${themesDir}/modules.jsonc" "$cfg_dir/modules.jsonc"
      fi
    '';

    ##########################################################################
    # Install Waybar theme switcher scripts into ~/.local/bin
    ##########################################################################
    home.file.".local/bin/waybar-switch-theme" = {
      source = scriptsDir + "/waybar-switch-theme.sh";
      executable = true;
    };
    home.file.".local/bin/waybar-pick-theme" = {
      source = scriptsDir + "/waybar-pick-theme.sh";
      executable = true;
    };

    ##########################################################################
    # Single owner: declarative systemd user service for Waybar
    # Uses ~/.config/waybar/{config,style.css} which the switcher maintains.
    ##########################################################################
    systemd.user.services."waybar-managed" = {
      Unit = {
        Description = "Waybar (managed by Home Manager; uses ~/.config/waybar/{config,style.css})";
        After  = [ "hyprland-env.service" "hyprland-session.target" ];
        PartOf = [ "hyprland-session.target" ];
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
        WantedBy = [ "hyprland-session.target" ];
      };
    };

    ##########################################################################
    # Ensure ~/.local/bin is present in PATH (append)
    ##########################################################################
    home.sessionPath = lib.mkAfter [ "$HOME/.local/bin" ];
  };
}


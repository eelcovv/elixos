{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;
  scriptsDir = ./scripts;

  cfgPath = "${config.xdg.configHome}/waybar";

  # Wait until Hyprland IPC is ready to avoid race conditions
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
    # Enable Waybar, but do not let HM auto-manage the systemd unit
    programs.waybar.enable = true;
    programs.waybar.package = pkgs.waybar;
    programs.waybar.systemd.enable = false;

    # Custom, robust systemd --user unit for Waybar
    systemd.user.services."waybar-managed" = {
      Unit = {
        Description = "Waybar (managed by Home Manager; uses ~/.config/waybar/{config,style.css})";
        # Depend on Hyprland session and the env-importer (Option A keeps this)
        After = ["graphical-session.target" "hyprland-session.target" "hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
        Conflicts = ["waybar.service"]; # avoid double starts
      };
      Service = {
        Type = "simple";

        # Multiple ExecStartPre commands must be a list
        ExecStartPre = [
          "${waitForHypr}"
          "${pkgs.coreutils}/bin/sleep 0.25"
        ];

        # Ensure runtime dir when launched by systemd --user
        Environment = [
          "XDG_RUNTIME_DIR=%t"
          "WAYBAR_CONFIG=%h/.config/waybar/config.jsonc"
          "WAYBAR_STYLE=%h/.config/waybar/style.css"
        ];

        # Trace level exposes JSONC mistakes or module load errors quickly
        ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config.jsonc -s ${cfgPath}/style.css";
        ExecReload = "${pkgs.coreutils}/bin/kill -USR2 $MAINPID";
        Restart = "on-failure";
        RestartSec = "1s";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # Publish read-only themes from the store
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # Seed writable user files on first deploy (no store symlinks)
    home.activation.ensureWaybarSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      mkdir -p "$cfg_dir"

      if [ ! -f "$cfg_dir/config.jsonc" ]; then
        install -Dm0644 "${themesDir}/default/config.jsonc" "$cfg_dir/config.jsonc"
      fi
      if [ ! -f "$cfg_dir/style.css" ]; then
        install -Dm0644 "${themesDir}/default/style.css" "$cfg_dir/style.css"
      fi
      if [ ! -f "$cfg_dir/colors.css" ]; then
        printf '/* default colors */\n' >"$cfg_dir/colors.css"
        chmod 0644 "$cfg_dir/colors.css"
      fi
      if [ ! -f "$cfg_dir/modules.jsonc" ]; then
        printf '{}\n' >"$cfg_dir/modules.jsonc"
        chmod 0644 "$cfg_dir/modules.jsonc"
      fi
      if [ ! -f "$cfg_dir/waybar-quicklinks.json" ]; then
        printf '[]\n' >"$cfg_dir/waybar-quicklinks.json"
        chmod 0644 "$cfg_dir/waybar-quicklinks.json"
      fi

      # Compat symlink some tools expect
      ln -sfn "$cfg_dir/config.jsonc" "$cfg_dir/config"
    '';

    # Helper tools in PATH
    home.file.".local/bin/waybar-switch-theme" = {
      source = scriptsDir + "/waybar-switch-theme.sh";
      executable = true;
    };
    home.file.".local/bin/waybar-pick-theme" = {
      source = scriptsDir + "/waybar-pick-theme.sh";
      executable = true;
    };

    # Make sure local bin is at the end of PATH for the session
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

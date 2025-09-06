{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;

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

    # Tools we click/open from Waybar
    home.packages = with pkgs; [
      pavucontrol
      pamixer
      wlogout
      blueman
      networkmanagerapplet
      jq
      gnome-calculator
      qalculate-gtk
      wofi
      wl-clipboard
      playerctl
      bc
      htop
    ];

    # Robust user service for Waybar
    systemd.user.services."waybar-managed" = {
      Unit = {
        Description = "Waybar (managed by Home Manager; uses ~/.config/waybar/{config,style.css})";
        After = ["graphical-session.target" "hyprland-session.target" "hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
        Conflicts = ["waybar.service"];
      };
      Service = {
        Type = "simple";
        ExecStartPre = [
          "${waitForHypr}"
          "${pkgs.coreutils}/bin/sleep 0.25"
        ];
        Environment = [
          "XDG_RUNTIME_DIR=%t"
          "WAYBAR_CONFIG=%h/.config/waybar/config.jsonc"
          "WAYBAR_STYLE=%h/.config/waybar/style.css"
        ];
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

      # Always write our config.jsonc/modules.jsonc (these are "your" active files)
      install -Dm0644 "${themesDir}/default/config.jsonc" "$cfg_dir/config.jsonc" || true
      install -Dm0644 "${themesDir}/default/style.css"   "$cfg_dir/style.css"   || true

      # If missing, create simple companions
      [ -f "$cfg_dir/colors.css" ] || { printf '/* default colors */\n' >"$cfg_dir/colors.css"; chmod 0644 "$cfg_dir/colors.css"; }
      [ -f "$cfg_dir/modules.jsonc" ] || { printf '{}\n' >"$cfg_dir/modules.jsonc"; chmod 0644 "$cfg_dir/modules.jsonc"; }
      [ -f "$cfg_dir/waybar-quicklinks.json" ] || { printf '[]\n' >"$cfg_dir/waybar-quicklinks.json"; chmod 0644 "$cfg_dir/waybar-quicklinks.json"; }

      ln -sfn "$cfg_dir/config.jsonc" "$cfg_dir/config"
    '';

    # Helper tools in PATH (theme switchers)
    home.file.".local/bin/waybar-switch-theme" = {
      source = waybarDir + "/scripts/waybar-switch-theme.sh";
      executable = true;
    };
    home.file.".local/bin/waybar-pick-theme" = {
      source = waybarDir + "/scripts/waybar-pick-theme.sh";
      executable = true;
    };

    # Small wrapper to open a system monitor on clicks from CPU/MEM/DISK modules
    home.file.".local/bin/system-monitor" = {
      text = ''
        #!/usr/bin/env bash
        if command -v gnome-system-monitor >/dev/null 2>&1; then
          exec gnome-system-monitor
        elif command -v mate-system-monitor >/dev/null 2>&1; then
          exec mate-system-monitor
        elif command -v kitty >/dev/null 2>&1; then
          exec kitty -e htop
        elif command -v alacritty >/dev/null 2>&1; then
          exec alacritty -e htop
        else
          exec ${pkgs.xterm}/bin/xterm -e htop
        fi
      '';
      executable = true;
    };

    # Ensure ~/.local/bin is last in session PATH
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

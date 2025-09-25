{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;

  # Set your preferred initial theme here (only used on first seed)
  defaultTheme = "default";

  cfgPath = "${config.xdg.configHome}/waybar";

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
    programs.waybar.enable = true;
    programs.waybar.package = pkgs.waybar;
    # We draaien onze eigen user service i.p.v. de standaard HM-unit
    programs.waybar.systemd.enable = false;

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

    # ---------------------------
    # Waybar (managed) user service
    # ---------------------------
    systemd.user.services."waybar-managed" = {
      Unit = {
        Description = "Waybar (managed by Home Manager; uses ~/.config/waybar/{config,style.css})";
        After = ["graphical-session.target" "hyprland-session.target" "hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
        Conflicts = ["waybar.service"];
      };
      Service = {
        Type = "simple";
        Environment = ["XDG_RUNTIME_DIR=%t"];
        ExecStartPre = [
          "${waitForHypr}"
          "${pkgs.coreutils}/bin/sleep 0.25"
        ];
        ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config -s ${cfgPath}/style.css";
        Restart = "on-failure";
        RestartSec = "1s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # ---------------------------
    # nm-applet als SNI tray (voor klein wifi-icoon in de tray)
    # ---------------------------
    systemd.user.services."nm-applet" = {
      Unit = {
        Description = "NetworkManager tray applet (StatusNotifier)";
        PartOf = ["hyprland-session.target"];
        After = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
        Restart = "on-failure";
        RestartSec = 1;
        Environment = ["XDG_RUNTIME_DIR=%t"];
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # ---------------------------
    # Read-only themes uit de store
    # ---------------------------
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # ---------------------------
    # Eén bron voor modules & quicklinks vanuit je repo
    # ---------------------------
    xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
    xdg.configFile."waybar/waybar-quicklinks.json".source = waybarDir + "/waybar-quicklinks.jsonc";

    # ---------------------------
    # Init seed (idempotent): maak symlinks naar gekozen theme
    # (Alleen als er nog NIETS is; laat user daarna vrij om via waybar-pick-theme te wisselen)
    # ---------------------------
    home.activation.waybarInitialSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      mkdir -p "$cfg_dir"

      # Als config.jsonc ontbreekt: symlink naar gekozen theme
      if [ ! -e "$cfg_dir/config.jsonc" ]; then
        ln -sfn "$cfg_dir/themes/${defaultTheme}/config.jsonc" "$cfg_dir/config.jsonc"
      fi

      # Als style.css ontbreekt: symlink naar gekozen theme
      if [ ! -e "$cfg_dir/style.css" ]; then
        ln -sfn "$cfg_dir/themes/${defaultTheme}/style.css" "$cfg_dir/style.css"
      fi

      # Colors is user-mutabel; alleen aanmaken als het ontbreekt
      if [ ! -e "$cfg_dir/colors.css" ]; then
        printf '/* user colors (optional) */\n' >"$cfg_dir/colors.css"
        chmod 0644 "$cfg_dir/colors.css"
      fi

      # Compat-symlink zodat -c ${cfgPath}/config het JSONC-bestand gebruikt
      ln -sfn "$cfg_dir/config.jsonc" "$cfg_dir/config"
    '';

    # ---------------------------
    # Kleine helper via modules
    # ---------------------------
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

    home.file.".local/bin/waybar-hypridle" = {
      source = waybarDir + "/scripts/waybar-hypridle.sh";
      executable = true;
    };

    home.file.".local/bin/waybar-pick-theme" = {
      source = waybarDir + "/scripts/waybar-pick-theme.sh";
      executable = true;
    };

    home.file.".local/bin/waybar-switch-theme" = {
      source = waybarDir + "/scripts/waybar-switch-theme.sh";
      executable = true;
    };
  };
}

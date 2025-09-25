{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;

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
    # We beheren Waybar via onze eigen user service hieronder:
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
        # belangrijk: runtime dir voor user services
        Environment = ["XDG_RUNTIME_DIR=%t"];
        ExecStartPre = [
          "${waitForHypr}"
          "${pkgs.coreutils}/bin/sleep 0.25"
        ];
        # zelfde paden als je cli die werkt
        ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config -s ${cfgPath}/style.css";
        Restart = "on-failure";
        RestartSec = "1s";
        # optioneel: forceer logging naar journal (meestal default, kan helpen)
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # ---------------------------
    # Script: waybar-hypridle (naar ~/.local/bin)
    # ---------------------------
    home.file.".local/bin/waybar-hypridle" = {
      source = waybarDir + "/scripts/waybar-hypridle.sh";
      executable = true;
    };

    systemd.user.services."nm-applet" = {
      Unit = {
        Description = "NetworkManager tray applet (StatusNotifier)";
        PartOf = ["hyprland-session.target"];
        After = ["hyprland-session.target"];
      };
      Service = {
        # --indicator requests SNI/AppIndicator mode suitable for Wayland
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
        Restart = "on-failure";
        RestartSec = 1;
        Environment = ["XDG_RUNTIME_DIR=%t"];
      };
      Install = {
        WantedBy = ["hyprland-session.target"];
      };
    };

    # Read-only themes from the store
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # Link your repo's modules.jsonc and quicklinks into ~/.config/waybar/
    xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
    xdg.configFile."waybar/waybar-quicklinks.json".source = waybarDir + "/waybar-quicklinks.jsonc";

    # Seed only the truly user-mutable files (config.jsonc, style.css, colors.css)
    home.activation.ensureWaybarSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      mkdir -p "$cfg_dir"

      # Only create these if absent; don't create modules/quicklinks here anymore
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

      # Compat symlink so waybar -c ${cfgPath}/config uses the JSONC
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

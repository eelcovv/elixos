{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;
  defaultTheme = "default"; # initial one-time seed
  cfgPath = "${config.xdg.configHome}/waybar";

  # Wait until Hyprland responds; avoids races when user services start
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
    programs.waybar.systemd.enable = false; # we manage our own unit

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
    # nm-applet as SNI tray (Wi-Fi icon)
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
    # Read-only themes (from repo → Nix store)
    # ---------------------------
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # Static JSON from repo (ok to symlink)
    xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
    xdg.configFile."waybar/waybar-quicklinks.json".source = waybarDir + "/waybar-quicklinks.jsonc";

    # ---------------------------
    # Writable seed for user-mutable files
    # - If absent or a symlink: replace with a real file (copy) so scripts can write
    # ---------------------------
    home.activation.waybarInitialSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      mkdir -p "''${cfg_dir}"

      seed_conf="''${cfg_dir}/config.jsonc"
      seed_style="''${cfg_dir}/style.css"
      seed_colors="''${cfg_dir}/colors.css"

      # Replace symlink or missing config.jsonc with a real file
      if [ -L "''${seed_conf}" ] || [ ! -f "''${seed_conf}" ]; then
        rm -f "''${seed_conf}"
        install -Dm0644 "${themesDir}/${defaultTheme}/config.jsonc" "''${seed_conf}"
      fi

      # Replace symlink or missing style.css with a real file
      if [ -L "''${seed_style}" ] || [ ! -f "''${seed_style}" ]; then
        rm -f "''${seed_style}"
        install -Dm0644 "${themesDir}/${defaultTheme}/style.css" "''${seed_style}"
      fi

      # Create colors.css if missing; keep it user-owned and writable
      if [ ! -f "''${seed_colors}" ]; then
        printf '/* user colors (optional) */\n' >"''${seed_colors}"
        chmod 0644 "''${seed_colors}"
      fi

      # Compat symlink so -c ${cfgPath}/config points at the JSONC
      ln -sfn "''${seed_conf}" "''${cfg_dir}/config"
    '';

    # ---------------------------
    # Helper scripts
    # ---------------------------
    home.file.".local/bin/system-monitor" = {
      text = ''
        #!/usr/bin/env bash
        # Try a GUI monitor; fallback to terminal htop
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

{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;
  defaultTheme = "ml4w-blur"; # <- kies je basis theme-map
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

    # --- Read-only themes (from repo → Nix store) ---
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # Static JSON from repo
    xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
    xdg.configFile."waybar/waybar-quicklinks.json".source = waybarDir + "/waybar-quicklinks.jsonc";

    # ---------------------------
    # Writable seed for user-mutable files (OLD, WERKEND MODEL)
    # ---------------------------
    home.activation.waybarInitialSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      mkdir -p "''${cfg_dir}"

      seed_conf="''${cfg_dir}/config.jsonc"
      seed_style="''${cfg_dir}/style.css"
      seed_colors="''${cfg_dir}/colors.css"
      compat_config_link="''${cfg_dir}/config"
      compat_current_link="''${cfg_dir}/current"

      # (1) Kopieer config.jsonc als echte file (indien symlink of ontbreekt)
      if [ -L "''${seed_conf}" ] || [ ! -f "''${seed_conf}" ]; then
        rm -f "''${seed_conf}"
        install -Dm0644 "${themesDir}/${defaultTheme}/config.jsonc" "''${seed_conf}"
      fi

      # (2) Kopieer style.css als echte file (indien symlink of ontbreekt)
      #     - Laat je scripts hier gewoon in schrijven (loaderregel, etc.)
      if [ -L "''${seed_style}" ] || [ ! -f "''${seed_style}" ]; then
        rm -f "''${seed_style}"
        install -Dm0644 "${themesDir}/${defaultTheme}/style.css" "''${seed_style}"
      fi

      # (3) User-kleurenfile (optioneel, writable)
      if [ ! -f "''${seed_colors}" ]; then
        printf '/* user colors (optional) */\n' >"''${seed_colors}"
        chmod 0644 "''${seed_colors}"
      fi

      # (4) Compat: config → config.jsonc (Waybar start met -c ~/.config/waybar/config)
      ln -sfn "''${seed_conf}" "''${compat_config_link}"

      # (5) Compat: current → themes (jouw loader @import "current/…/style.css" blijft werken)
      #     Voorbeeld: @import "current/ml4w-blur/light/style.css";
      ln -sfn "''${cfg_dir}/themes" "''${compat_current_link}"
    '';

    # ---------------------------
    # Helper scripts (blijven zoals je had)
    # ---------------------------
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
    # GTK icon theme + nm-applet (symbolic icons → recolorbaar)
    # ---------------------------
    gtk = {
      enable = true;
      iconTheme = {
        name = "Adwaita"; # of "Papirus-Dark"/"Papirus-Light"
        package = pkgs.adwaita-icon-theme;
      };
      gtk3.extraConfig."gtk-application-prefer-dark-theme" = 1;
      gtk4.extraConfig."gtk-application-prefer-dark-theme" = 1;
    };

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
  };
}

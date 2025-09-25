{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;
  selectedTheme = "ml4w-blur"; # <-- pick your ML4W theme
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

    # --- Read-only themes from repo (available under ~/.config/waybar/themes) ---
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # --- Config stays a read-only symlink to the selected theme (JSONC) ---
    xdg.configFile."waybar/config".source = "${themesDir}/${selectedTheme}/config.jsonc";

    # --- Writable CSS files via activation (no symlinks) -----------------------
    home.activation.waybarWritableCss = lib.hm.dag.entryAfter ["writeBoundary"] ''
        set -eu

        cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
        mkdir -p "''${cfg_dir}"

        style_path="''${cfg_dir}/style.css"
        custom_path="''${cfg_dir}/custom.css"

        # Ensure style.css is a REAL file (wrapper) instead of a symlink
        if [ -L "''${style_path}" ] || [ ! -f "''${style_path}" ]; then
          rm -f "''${style_path}"
          # Use single-quoted heredoc to avoid shell var expansion; we inject Nix vars now.
          cat > "''${style_path}" <<'EOF'
      /* Base theme (read-only in Nix store) */
      @import url("''${XDG_CONFIG_HOME:-$HOME/.config}/waybar/themes/REPLACE_SELECTED_THEME/style.css");

      /* Full user overrides (writable) */
      @import url("custom.css");
      EOF
          # Inject the selected theme name into the file (safe in POSIX sh)
          ${pkgs.coreutils}/bin/sed -i "s|REPLACE_SELECTED_THEME|${selectedTheme}|g" "''${style_path}"
          chmod 0644 "''${style_path}"
        fi

        # Ensure custom.css exists as a REAL, writable file
        if [ -L "''${custom_path}" ]; then
          rm -f "''${custom_path}"
        fi
        if [ ! -f "''${custom_path}" ]; then
          printf '/* your overrides here */\n' > "''${custom_path}"
          chmod 0644 "''${custom_path}"
        fi
    '';

    # --- Keep colors.css as optional writable (if you still use it) ------------
    home.file.".config/waybar/colors.css" = {
      text = "/* user colors (optional) */\n";
      force = false;
    };

    # --- Helper scripts --------------------------------------------------------
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

    # --- Waybar managed service -----------------------------------------------
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

    # --- GTK icon theme so nm-applet can use symbolic icons (recolorable) -----
    gtk = {
      enable = true;
      iconTheme = {
        name = "Adwaita"; # or "Papirus-Dark"/"Papirus-Light"
        package = pkgs.adwaita-icon-theme;
      };
      gtk3.extraConfig."gtk-application-prefer-dark-theme" = 1;
      gtk4.extraConfig."gtk-application-prefer-dark-theme" = 1;
    };

    # --- nm-applet as StatusNotifier (symbolic when indicator is used) --------
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

    # --- Other static waybar JSON files you already had ------------------------
    xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
    xdg.configFile."waybar/waybar-quicklinks.json".source = waybarDir + "/waybar-quicklinks.jsonc";
  };
}

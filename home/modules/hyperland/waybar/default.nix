{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;
  defaultTheme = "ml4w-blur"; # set your default theme family
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

    # Read-only themes from repo
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # Static JSON from repo
    xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
    xdg.configFile."waybar/waybar-quicklinks.json".source = waybarDir + "/waybar-quicklinks.jsonc";

    # Seed: create stable symlinks
    home.activation.waybarInitialSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      mkdir -p "''${cfg_dir}"

      current_link="''${cfg_dir}/current"
      config_link="''${cfg_dir}/config"
      default_dir="''${cfg_dir}/themes/${defaultTheme}"

      # Ensure 'current' points to the default theme directory
      if [ -e "''${current_link}" ] && [ ! -L "''${current_link}" ]; then
        rm -rf "''${current_link}"
      fi
      ln -sfnT "''${default_dir}" "''${current_link}"

      # Point 'config' to theme's config.jsonc (preferred) or config
      if [ -f "''${default_dir}/config.jsonc" ]; then
        ln -sfnT "''${default_dir}/config.jsonc" "''${config_link}"
      elif [ -f "''${default_dir}/config" ]; then
        ln -sfnT "''${default_dir}/config" "''${config_link}"
      else
        echo "WARNING: No config(.jsonc) in ''${default_dir}; Waybar may fail to start" >&2
      fi
    '';

    # Helper scripts
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

    # Waybar (managed) user service
    systemd.user.services."waybar-managed" = {
      Unit = {
        Description = "Waybar (managed)";
        After = ["graphical-session.target" "hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "simple";
        Environment = ["XDG_RUNTIME_DIR=%t"];
        ExecStartPre = ["${waitForHypr}" "${pkgs.coreutils}/bin/sleep 0.25"];

        # IMPORTANT: CSS from the active theme via 'current'
        ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config -s ${cfgPath}/current/style.css";

        # Be gentle on stop; no wide pkill to avoid killing the new instance
        TimeoutStopSec = "2s";
        KillMode = "mixed";

        Restart = "on-failure";
        RestartSec = "1s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # nm-applet service (unchanged)
    systemd.user.services."nm-applet" = {
      Unit = {
        Description = "NetworkManager Applet";
        After = ["graphical-session.target" "hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
        TimeoutStopSec = "2s";
        KillMode = "mixed";
        Restart = "on-failure";
        RestartSec = 1;
        Environment = ["XDG_RUNTIME_DIR=%t"];
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # GTK icon theme
    gtk = {
      enable = true;
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
      gtk3.extraConfig."gtk-application-prefer-dark-theme" = 1;
      gtk4.extraConfig."gtk-application-prefer-dark-theme" = 1;
    };
  };
}

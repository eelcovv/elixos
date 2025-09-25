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

  # Wait for a Wayland session (Hyprland/Sway/etc.) to be up
  waitForWL = pkgs.writeShellScript "wait-for-wayland" ''
    set -eu
    # Wait up to ~5s for a Wayland compositor to expose env or socket
    for i in $(seq 1 50); do
      if [ -n "''${WAYLAND_DISPLAY-}" ] || [ -n "''${HYPERLAND_INSTANCE_SIGNATURE-}" ]; then
        exit 0
      fi
      # Also check if a hyprland instance is around (best-effort)
      if command -v pgrep >/dev/null 2>&1 && pgrep -x hyprland >/dev/null 2>&1; then
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

    # Read-only themes from repo (→ Nix store)
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # Static JSON from repo
    xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
    xdg.configFile."waybar/waybar-quicklinks.json".source = waybarDir + "/waybar-quicklinks.jsonc";

    # Seed: ensure stable symlinks exist on first activation (idempotent)
    home.activation.waybarInitialSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      mkdir -p "''${cfg_dir}"

      current_link="''${cfg_dir}/current"
      config_link="''${cfg_dir}/config"
      default_dir="''${cfg_dir}/themes/${defaultTheme}"

      # Ensure 'current' points to default theme directory
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
        # Use graphical-session.target which Home Manager provides reliably
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        # Make sure Wayland env is available to the service
        Environment = [
          "XDG_RUNTIME_DIR=%t"
          # Hyprland typically exports these for user services, but we don't hard-require them
        ];
        ExecStartPre = ["${waitForWL}" "${pkgs.coreutils}/bin/sleep 0.25"];

        # CSS is read from the active theme via 'current'
        ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config -s ${cfgPath}/current/style.css";

        # Gentle stop; avoid broad pkill which could race with restarts
        TimeoutStopSec = "2s";
        KillMode = "mixed";

        Restart = "on-failure";
        RestartSec = "1s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    # NetworkManager applet (unchanged)
    systemd.user.services."nm-applet" = {
      Unit = {
        Description = "NetworkManager Applet";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
        TimeoutStopSec = "2s";
        KillMode = "mixed";
        Restart = "on-failure";
        RestartSec = 1;
        Environment = ["XDG_RUNTIME_DIR=%t"];
      };
      Install.WantedBy = ["graphical-session.target"];
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

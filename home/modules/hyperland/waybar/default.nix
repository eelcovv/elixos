{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;
  defaultTheme = "ml4w-blur"; # choose your default theme family
  cfgPath = "${config.xdg.configHome}/waybar";

  # Wait for Wayland session (Hyprland/Sway/etc.)
  waitForWL = pkgs.writeShellScript "wait-for-wayland" ''
    set -eu
    for i in $(seq 1 50); do
      if [ -n "''${WAYLAND_DISPLAY-}" ] || [ -n "''${HYPERLAND_INSTANCE_SIGNATURE-}" ]; then
        exit 0
      fi
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

    # Read-only themes from repo → Nix store
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # Static JSON from repo
    xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
    xdg.configFile."waybar/waybar-quicklinks.json".source = waybarDir + "/waybar-quicklinks.jsonc";

    # Stable wrapper config that includes the active theme config
    xdg.configFile."waybar/config.jsonc".text = ''
      {
        // ===== Safe defaults to keep bar visible =====
        "layer": "top",
        "position": "top",
        "height": 43,
        "exclusive-zone": true,
        "output": [ "*" ],
        // Load the active theme config from the moving 'current' symlink
        "include": [ "${cfgPath}/current/config.jsonc", "${cfgPath}/current/config" ]
      }
    '';

    # Fallback colors.css used when a theme lacks its own colors.css
    xdg.configFile."waybar/colors.css".text = ''
      /* GTK CSS fallback for Waybar themes that @import "colors.css" */
      @define-color bar-bg            rgba(0,0,0,0.55);
      @define-color bar-fg            #eaeaea;
      @define-color accent            #5e81ac;
      @define-color ok                #a3be8c;
      @define-color warn              #ebcb8b;
      @define-color err               #bf616a;

      /* Veelgebruikte namen die sommige themes gebruiken */
      @define-color background        @bar-bg;
      @define-color foreground        @bar-fg;
      @define-color primary           @accent;
      @define-color success           @ok;
      @define-color warning           @warn;
      @define-color error             @err;

      /* ML4W-achtige naamgevingen (voor de zekerheid) */
      @define-color wb-bg             @bar-bg;
      @define-color wb-fg             @bar-fg;
      @define-color wb-hl             @accent;
    '';

    # Seed: ensure 'current' points to default theme directory (idempotent)
    home.activation.waybarInitialSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      mkdir -p "''${cfg_dir}"

      current_link="''${cfg_dir}/current"
      default_dir="''${cfg_dir}/themes/${defaultTheme}"

      if [ -e "''${current_link}" ] && [ ! -L "''${current_link}" ]; then
        rm -rf "''${current_link}"
      fi
      ln -sfnT "''${default_dir}" "''${current_link}"
    '';

    # Ensure 'current/colors.css' always exists (fallback link)
    home.activation.waybarColorsGuard = lib.hm.dag.entryAfter ["waybarInitialSeed"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      cur_dir="''${cfg_dir}/current"
      mkdir -p "''${cur_dir}"
      if [ ! -e "''${cur_dir}/colors.css" ]; then
        ln -sfn "''${cfg_dir}/colors.css" "''${cur_dir}/colors.css"
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
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        Environment = ["XDG_RUNTIME_DIR=%t"];
        ExecStartPre = ["${waitForWL}" "${pkgs.coreutils}/bin/sleep 0.25"];

        # Use fixed wrapper config; CSS from 'current'
        ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config.jsonc -s ${cfgPath}/current/style.css";

        TimeoutStopSec = "2s";
        KillMode = "mixed";
        Restart = "on-failure";
        RestartSec = "1s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    # nm-applet (unchanged)
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

{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;

  # --- Defaults you can tweak ---
  defaultTheme = "ml4w-blur"; # theme family
  defaultVariant = "light"; # subvariant: "light" | "dark"

  cfgPath = "${config.xdg.configHome}/waybar";

  # Wait until a Wayland compositor (Hyprland/Sway) is ready
  waitForWL = pkgs.writeShellScript "wait-for-wayland" ''
    set -eu
    for i in $(seq 1 50); do
      # Fixed typo: HYPRLAND_INSTANCE_SIGNATURE
      if [ -n "''${WAYLAND_DISPLAY-}" ] || [ -n "''${HYPRLAND_INSTANCE_SIGNATURE-}" ]; then
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
    programs.waybar.systemd.enable = false; # We manage our own unit

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

    # Read-only themes from the repository → Nix store
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # Static JSON files from repository (included by theme config)
    xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
    xdg.configFile."waybar/waybar-quicklinks.json".source = waybarDir + "/waybar-quicklinks.jsonc";

    # --- Activation steps to wire symlinks ---

    # Seed 'current' → default theme family
    home.activation.waybarCurrentSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
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

    # Ensure 'active' → chosen variant
    home.activation.waybarActiveVariant = lib.hm.dag.entryAfter ["waybarCurrentSeed"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      cur_dir="''${cfg_dir}/current"
      act_link="''${cfg_dir}/active"
      var_dir="''${cur_dir}/${defaultVariant}"

      # Fallback if preferred variant does not exist
      if [ ! -d "''${var_dir}" ]; then
        if first=$(find "''${cur_dir}" -mindepth 1 -maxdepth 1 -type d | head -n1); then
          var_dir="''${first}"
        fi
      fi

      ln -sfnT "''${var_dir}" "''${act_link}"
    '';

    # Link top-level files
    home.activation.waybarTopLevelLinks = lib.hm.dag.entryAfter ["waybarActiveVariant"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      cur_dir="''${cfg_dir}/current"

      # config.jsonc -> current/config.jsonc (family config)
      ln -sfn "''${cur_dir}/config.jsonc" "''${cfg_dir}/config.jsonc"

      # style.css (top-level) -> current/style.css (family base style)
      if [ -f "''${cur_dir}/style.css" ]; then
        ln -sfn "''${cur_dir}/style.css" "''${cfg_dir}/style.css"
      fi
    '';

    # Fallback colors.css if missing
    xdg.configFile."waybar/colors.css".text = ''
      /* GTK CSS fallback for Waybar themes that @import "colors.css" */
      @define-color bar-bg rgba(0,0,0,0.55);
      @define-color bar-fg #eaeaea;
      @define-color accent #5e81ac;
      @define-color ok #a3be8c;
      @define-color warn #ebcb8b;
      @define-color err #bf616a;
    '';

    # Ensure colors.css exists in family and variant
    home.activation.waybarColorsGuard = lib.hm.dag.entryAfter ["waybarTopLevelLinks"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      cur_dir="''${cfg_dir}/current"
      act_dir="''${cfg_dir}/active"

      if [ ! -e "''${cur_dir}/colors.css" ]; then
        ln -sfn "''${cfg_dir}/colors.css" "''${cur_dir}/colors.css"
      fi
      if [ ! -e "''${act_dir}/colors.css" ]; then
        ln -sfn "''${cur_dir}/colors.css" "''${act_dir}/colors.css"
      fi
    '';

    # Hide any global Waybar autostart desktop entry (prevents duplicate launch)
    xdg.autostart."waybar.desktop".text = ''
      [Desktop Entry]
      Name=Waybar
      Exec=waybar
      Type=Application
      Hidden=true
    '';

    # Custom helper scripts
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

    # Main Waybar systemd-managed service (single instance)
    systemd.user.services."waybar-managed" = {
      Unit = {
        Description = "Waybar (managed)";
        After = ["hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
        Conflicts = ["waybar.service"]; # Prevent duplicate legacy unit
      };
      Service = {
        Type = "simple";
        Environment = ["XDG_RUNTIME_DIR=%t"];
        # Kill any stray Waybar before starting
        ExecStartPre = [
          "${pkgs.procps}/bin/pkill -x waybar || true"
          "${waitForWL}"
          "${pkgs.coreutils}/bin/sleep 0.25"
        ];
        ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config.jsonc -s ${cfgPath}/active/style.css";
        TimeoutStopSec = "2s";
        KillMode = "mixed";
        Restart = "on-failure";
        RestartSec = "1s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # NetworkManager tray applet (systemd-managed)
    systemd.user.services."nm-applet" = {
      Unit = {
        Description = "NetworkManager Applet";
        After = ["hyprland-session.target"];
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

    # GTK configuration
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

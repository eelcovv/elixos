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

    # --- Read-only themes (from repo → Nix store) --m
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

      # Compat: config → config.jsonc  (forceer symlink op bestemming)
      ln -sfnT "''${seed_conf}" "''${compat_config_link}"

      # Compat: current → themes  (eerst echte directory opruimen, dan -T gebruiken)
      if [ -e "''${compat_current_link}" ] && [ ! -L "''${compat_current_link}" ]; then
        rm -rf "''${compat_current_link}"
      fi
      ln -sfnT "''${cfg_dir}/themes" "''${compat_current_link}"
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
        /*
        …zoals je had…
        */
      };
      Service = {
        Type = "simple";
        Environment = ["XDG_RUNTIME_DIR=%t"];
        ExecStartPre = ["${waitForHypr}" "${pkgs.coreutils}/bin/sleep 0.25"];
        ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config -s ${cfgPath}/style.css";

        # ↓ deze drie regels helpen tegen vastlopers bij stop/restart
        TimeoutStopSec = "2s";
        KillMode = "mixed";
        ExecStopPost = "${pkgs.procps}/bin/pkill -9 -f '(^|/)waybar($| )' || true";

        Restart = "on-failure";
        RestartSec = "1s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    systemd.user.services."nm-applet" = {
      Unit = {
        /*
        …zoals je had…
        */
      };
      Service = {
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";

        # idem dito, kort stoppen en daarna hard killen indien nodig
        TimeoutStopSec = "2s";
        KillMode = "mixed";
        ExecStopPost = "${pkgs.procps}/bin/pkill -9 -f '(^|/)nm-applet($| )' || true";

        Restart = "on-failure";
        RestartSec = 1;
        Environment = ["XDG_RUNTIME_DIR=%t"];
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
  };
}

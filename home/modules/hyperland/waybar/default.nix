{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;
  selectedTheme = "ml4w-blur"; # initial default
  cfgPath = "${config.xdg.configHome}/waybar";

  waitForHypr = pkgs.writeShellScript "wait-for-hypr" ''
    for i in $(seq 1 50); do
      if ${pkgs.hyprland}/bin/hyprctl -j monitors >/dev/null 2>&1; then exit 0; fi
      sleep 0.1
    done
    exit 0
  '';
in {
  config = {
    programs.waybar.enable = true;
    programs.waybar.package = pkgs.waybar;
    programs.waybar.systemd.enable = false;

    # Theme directory (read-only from repo)
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # >>> Writable setup driven by 'current' symlink <<<
    # We ensure:
    #  - ~/.config/waybar/current  -> ~/.config/waybar/themes/<theme>
    #  - ~/.config/waybar/config   -> ~/.config/waybar/current/config.jsonc
    #  - ~/.config/waybar/style.css (wrapper) imports ~/.config/waybar/current/style.css + custom.css
    #  - ~/.config/waybar/custom.css exists (writable)
    home.activation.waybarWritableLayout = lib.hm.dag.entryAfter ["writeBoundary"] ''
            set -eu
            cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
            mkdir -p "''${cfg_dir}"

            # 1) Ensure 'current' symlink exists (default to ${selectedTheme})
            target="''${cfg_dir}/themes/${selectedTheme}"
            if [ ! -e "''${cfg_dir}/current" ]; then
              ln -sfn "''${target}" "''${cfg_dir}/current"
            fi

            # 2) Ensure 'config' points to current/config.jsonc (regular symlink in $HOME)
            ln -sfn "''${cfg_dir}/current/config.jsonc" "''${cfg_dir}/config"

            # 3) Ensure style.css is a REAL writable wrapper (not a store symlink)
            style_path="''${cfg_dir}/style.css"
            if [ -L "''${style_path}" ] || [ ! -f "''${style_path}" ]; then
              rm -f "''${style_path}"
              cat > "''${style_path}" <<EOF
      /* Base theme (follows ~/.config/waybar/current) */
      @import url("${cfgPath}/current/style.css");

      /* Full user overrides (writable) */
      @import url("custom.css");
      EOF
              chmod 0644 "''${style_path}"
            fi

            # 4) Ensure custom.css exists and is writable
            custom_path="''${cfg_dir}/custom.css"
            if [ -L "''${custom_path}" ]; then rm -f "''${custom_path}"; fi
            if [ ! -f "''${custom_path}" ]; then
              printf '/* your overrides here */\n' > "''${custom_path}"
              chmod 0644 "''${custom_path}"
            fi
    '';

    # (optioneel) losse user-kleurenfile, als je die nog gebruikt
    home.file.".config/waybar/colors.css" = {
      text = "/* user colors (optional) */\n";
      force = false;
    };

    # Scripts blijven zoals je ze had
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

    # Waybar service
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
        ExecStartPre = ["${waitForHypr}" "${pkgs.coreutils}/bin/sleep 0.25"];
        ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config -s ${cfgPath}/style.css";
        Restart = "on-failure";
        RestartSec = "1s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # GTK icon theme (voor symbolic nm-applet icons)
    gtk = {
      enable = true;
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
      gtk3.extraConfig."gtk-application-prefer-dark-theme" = 1;
      gtk4.extraConfig."gtk-application-prefer-dark-theme" = 1;
    };

    # nm-applet (symbolic met --indicator)
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

    # overige statische JSONs
    xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
    xdg.configFile."waybar/waybar-quicklinks.json".source = waybarDir + "/waybar-quicklinks.jsonc";
  };
}

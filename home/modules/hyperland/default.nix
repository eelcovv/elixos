{
  config,
  pkgs,
  lib,
  ...
}: let
  hyprDir = ./.;
  scriptsDir = "${hyprDir}/scripts";
  wallpaperDir = ./wallpapers;
  wallpaperTargetDir = "${config.xdg.configHome}/wallpapers";
in {
  imports = [
    ./waybar
    ./waypaper
  ];

  config = {
    home.packages = with pkgs; [
      kitty
      hyprpaper
      hyprshot
      hyprlock
      hypridle
      inotify-tools
      wofi
      brightnessctl
      pavucontrol
      wl-clipboard
      cliphist
      matugen
      wallust
      waypaper
    ];

    # User session target for Hyprland (user-level)
    systemd.user.targets."hyprland-session" = {
      Unit = {
        Description = "Hyprland graphical session (user)";
        Requires = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Install = {WantedBy = ["default.target"];};
    };

    # Notifications via systemd
    systemd.user.services."swaync" = {
      Unit = {
        Description = "SwayNotificationCenter";
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    # --- make sure ~/.local/bin ends up in the systemd user environment (for Hyprland exec / binds harmony)
    systemd.user.services."import-user-env" = {
      Unit = {
        Description = "Import PATH into systemd user environment";
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        # Export a PATH that includes ~/.local/bin and common Nix profiles, then import it into the user manager
        Environment = [
          "PATH=%h/.local/bin:%h/.nix-profile/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/bin:/bin"
        ];
        ExecStart = "${pkgs.systemd}/bin/systemctl --user import-environment PATH";
        RemainAfterExit = true;
      };
      Install = {WantedBy = ["default.target"];};
    };
    # --- END NEW

    home.sessionVariables = {
      WALLPAPER_DIR = wallpaperTargetDir;
      SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
    };

    # Hyprland configs (static files under ~/.config/hypr)
    xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
    xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
    xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
    xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
    xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
    xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
    xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

    # Sanity check: helper must exist (fail early if missing)
    home.activation.checkHyprHelper = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [ ! -r "$HOME/.config/hypr/scripts/helper-functions.sh" ]; then
        echo "ERROR: missing helper at ~/.config/hypr/scripts/helper-functions.sh" >&2
        exit 1
      fi
    '';

    # Install hypr-switch-displays into ~/.local/bin
    home.file.".local/bin/hypr-switch-displays" = {
      source = "${scriptsDir}/hypr-switch-displays.sh";
      executable = true;
    };

    home.file.".local/bin/hypr-display-watcher" = {
      text = builtins.readFile ./scripts/hypr-display-watcher.sh;
      executable = true;
    };

    systemd.user.services."hypr-display-watcher" = {
      Unit = {
        Description = "Auto switch displays on hotplug (Hyprland)";
        PartOf = ["hyprland-session.target"];
        After = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "%h/.local/bin/hypr-display-watcher";
        Restart = "always";
        RestartSec = 1;
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    # hyprpaper config + default wallpaper (Waypaper controls runtime)
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      ipc = on
      splash = false
      # preload = ${wallpaperTargetDir}/default.png
    '';
    xdg.configFile."${wallpaperTargetDir}/default.png".source = "${wallpaperDir}/nixos.png";

    # Ensure ~/.local/bin is in PATH for the session
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];

    # Waypaper options (consumed by ./waypaper module)
    hyprland.wallpaper.enable = true;
    hyprland.wallpaper.random.enable = true;
    hyprland.wallpaper.random.intervalSeconds = 1800;

    hyprland.wallpaper.fetch.enable = true;
    hyprland.wallpaper.fetch.onCalendar = "daily";
  };
}

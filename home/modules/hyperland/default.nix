{
  config,
  pkgs,
  lib,
  ...
}: let
  hyprDir = ./.;
  wallpaperDir = ./wallpapers;
  wallpaperTargetDir = "${config.xdg.configHome}/wallpapers";
in {
  imports = [
    ./waybar # Waybar config + systemd binding
    ./waypaper # Wallpaper integration (owns hyprpaper + timers)
  ];

  config = {
    ################################
    # Packages for Hyprland & desktop tools
    ################################
    home.packages = with pkgs; [
      kitty
      hyprpaper
      hyprshot
      hyprlock
      hypridle
      wofi
      brightnessctl
      pavucontrol
      wl-clipboard
      cliphist
      matugen
      wallust
      waypaper
    ];

    ################################
    # User target representing the Hyprland session
    ################################
    systemd.user.targets."hyprland-session" = {
      Unit = {
        Description = "Hyprland graphical session (user)";
        Requires = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Install = {WantedBy = ["default.target"];};
    };

    ################################
    # Import Hyprland environment into systemd --user
    ################################
    systemd.user.services."hyprland-env" = {
      Unit = {
        Description = "Import Hyprland session environment into systemd --user";
        After = ["graphical-session.target"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -lc '${pkgs.systemd}/bin/systemctl --user import-environment WAYLAND_DISPLAY XDG_RUNTIME_DIR XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE; ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_RUNTIME_DIR XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE'";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    ################################
    # Notifications (SwayNC) via systemd — do not autostart from Hyprland
    ################################
    systemd.user.services."swaync" = {
      Unit = {
        Description = "SwayNotificationCenter";
        After = ["hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    ################################
    # Session environment variables
    ################################
    home.sessionVariables = {
      WALLPAPER_DIR = wallpaperTargetDir;
      # Let runtime expand XDG_RUNTIME_DIR (avoid Nix-time interpolation):
      SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
    };

    ################################
    # Hyprland configuration files
    ################################
    xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
    xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
    xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
    xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";

    # Link read-only directories (do not also manage individual files inside):
    xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
    xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
    xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

    ################################
    # Optional sanity check: helper must exist
    ################################
    home.activation.checkHyprHelper = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [ ! -r "$HOME/.config/hypr/scripts/helper-functions.sh" ]; then
        echo "ERROR: missing helper at ~/.config/hypr/scripts/helper-functions.sh" >&2
        exit 1
      fi
    '';

    ################################
    # hyprpaper config + default wallpaper (Waypaper controls runtime)
    ################################
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      ipc = on
      splash = false
      preload = ${wallpaperTargetDir}/default.png
    '';

    xdg.configFile."${wallpaperTargetDir}/default.png".source = "${wallpaperDir}/nixos.png";

    ################################
    # Ensure ~/.local/bin is in PATH (append)
    ################################
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];

    ################################
    # Enable Waypaper integration module (owns hyprpaper + timers)
    ################################
    hyprland.wallpaper.enable = true;
    hyprland.wallpaper.random.enable = true;
    hyprland.wallpaper.random.intervalSeconds = 300;
  };
}

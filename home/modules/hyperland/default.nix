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
  # Pull in submodules (Waybar + Waypaper integration)
  imports = [
    ./waybar
    ./waypaper
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
    # Import Wayland/Hypr env into systemd --user
    # (so Waypaper/Hyprpaper see WAYLAND_DISPLAY / HYPRLAND_INSTANCE_SIGNATURE)
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
    # Waybar via systemd user (bound to hyprland-session target)
    ################################
    programs.waybar.enable = true;
    programs.waybar.systemd.enable = true;
    programs.waybar.systemd.target = "hyprland-session.target";

    home.activation.waybarPreClean = lib.hm.dag.entryBefore ["linkGeneration"] ''
      set -eu
      rm -f "$HOME/.config/waybar/config" \
            "$HOME/.config/waybar/config.jsonc" \
            "$HOME/.config/waybar/style.css" \
            "$HOME/.config/waybar/modules.jsonc" \
            "$HOME/.config/waybar/colors.css" || true
    '';

    ################################
    # Run hypridle as a robust user service
    ################################
    systemd.user.services."hypridle" = {
      Unit = {
        Description = "Hyprland idle daemon";
        After = ["hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.hypridle}/bin/hypridle";
        Restart = "always";
        RestartSec = "200ms";
        # Reads ~/.config/hypr/hypridle.conf by default
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    ################################
    # Session environment variables
    ################################
    home.sessionVariables = {
      WALLPAPER_DIR = wallpaperTargetDir;
      # keep literal for runtime expansion:
      SSH_AUTH_SOCK = "${"$XDG_RUNTIME_DIR"}/keyring/ssh";
    };

    ################################
    # Hyprland configuration files
    ################################
    xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
    xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
    xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
    xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
    xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
    xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
    # Install all helper scripts (including hypridle.sh, helper-functions.sh, etc.)
    xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

    # Sanity check: ensure helper exists after linking
    home.activation.checkHyprHelper = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [ ! -r "$HOME/.config/hypr/scripts/helper-functions.sh" ]; then
        echo "ERROR: missing helper at ~/.config/hypr/scripts/helper-functions.sh" >&2
        exit 1
      fi
    '';

    ################################
    # hyprpaper config + default wallpaper
    # (Waypaper/our module drives hyprpaper; we just provide config/default image)
    ################################
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      ipc = on
      splash = false
      preload = ${wallpaperTargetDir}/default.png
    '';
    xdg.configFile."${wallpaperTargetDir}/default.png".source = "${wallpaperDir}/nixos.png";

    ################################
    # Ensure ~/.local/bin is in PATH
    ################################
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];

    ################################
    # Enable the Waypaper integration module
    ################################
    hyprland.wallpaper.enable = true;

    # Random rotation settings (comment out to disable)
    #hyprland.wallpaper.random.enable = true;
    #hyprland.wallpaper.random.intervalSeconds = 300; # seconds
  };
}

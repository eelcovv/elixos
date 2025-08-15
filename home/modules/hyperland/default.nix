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
  # Import submodules (Waybar + Waypaper integration)
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
      hyprpaper # backend used by Waypaper
      hyprshot
      hyprlock
      hypridle
      wofi
      brightnessctl
      pavucontrol
      wl-clipboard
      cliphist
      # Wallpaper / theme helpers
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
    # (so Waypaper/hyprpaper see WAYLAND_DISPLAY / HYPRLAND_INSTANCE_SIGNATURE)
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

    ################################
    # Session environment variables
    ################################
    home.sessionVariables = {
      WALLPAPER_DIR = wallpaperTargetDir;
      SSH_AUTH_SOCK = "${"$XDG_RUNTIME_DIR"}/keyring/ssh"; # keep literal for runtime expansion
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
    xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

    ################################
    # Shared helper functions (used by Waybar/Waypaper)
    ################################
    home.file.".config/hypr/scripts/helper-functions.sh" = {
      source = "${hyprDir}/scripts/helper-functions.sh";
      executable = true;
    };

    # Sanity check: ensure helper exists after linking
    home.activation.checkHyprHelper = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [ ! -r "$HOME/.config/hypr/scripts/helper-functions.sh" ]; then
        echo "ERROR: missing helper at ~/.config/hypr/scripts/helper-functions.sh" >&2
        exit 1
      fi
    '';

    ################################
    # hyprpaper config + default wallpaper (Waypaper will drive the backend)
    ################################
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      ipc = on
      splash = false
      preload = ${wallpaperTargetDir}/default.png
    '';

    # Place the default wallpaper using the same target dir variable
    xdg.configFile."${wallpaperTargetDir}/default.png".source = "${wallpaperDir}/nixos.png";

    ################################
    # Ensure ~/.local/bin is in PATH
    ################################
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];

    ################################
    # Enable the Waypaper integration module
    ################################
    hyprland.wallpaper.enable = true;
  };
}

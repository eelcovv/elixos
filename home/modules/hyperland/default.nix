{
  config,
  pkgs,
  lib,
  ...
}: let
  # Root of this Hyprland module (contains hyprland.conf, subdirs, wallpapers, scripts, etc.)
  hyprDir = ./.;

  # Convenience – this resolves to "~/.config" at runtime
  cfgHome = config.xdg.configHome;
in {
  # Only import the Waybar module. We deliberately do NOT import a Waypaper module anymore.
  imports = [
    ./waybar
  ];

  config = {
    ########################################################################
    # Packages used in the Hyprland desktop session
    ########################################################################
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
    ];

    ########################################################################
    # Waybar handled by Hyprland (no systemd user unit to avoid double starts)
    ########################################################################
    programs.waybar.enable = true;
    programs.waybar.systemd.enable = false;

    # Clean potential legacy files that could cause Waybar to fall back to defaults
    home.activation.waybarPreClean = lib.hm.dag.entryBefore ["linkGeneration"] ''
      set -eu
      rm -f "$HOME/.config/waybar/config" \
            "$HOME/.config/waybar/config.jsonc" \
            "$HOME/.config/waybar/style.css" \
            "$HOME/.config/waybar/modules.jsonc" \
            "$HOME/.config/waybar/colors.css" || true
    '';

    ########################################################################
    # Session variables
    ########################################################################
    home.sessionVariables = {
      # Directory where wallpapers are managed (Hyprpaper reads current.png here)
      WALLPAPER_DIR = "${cfgHome}/wallpapers";

      # Keep literal expansion for runtime (Gnome Keyring/ssh-agent path)
      SSH_AUTH_SOCK = "${"$XDG_RUNTIME_DIR"}/keyring/ssh";
    };

    ########################################################################
    # Install Hyprland configuration and helper scripts declaratively
    ########################################################################
    xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
    xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
    xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
    xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
    xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
    xdg.configFile."hypr/effects".source = "${hyprDir}/effects";

    # All helper scripts used by your Hyprland setup (e.g., hypridle.sh, helper-functions.sh)
    xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

    # Sanity check to ensure required helper exists after linking
    home.activation.checkHyprHelper = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [ ! -r "$HOME/.config/hypr/scripts/helper-functions.sh" ]; then
        echo "ERROR: missing helper at ~/.config/hypr/scripts/helper-functions.sh" >&2
        exit 1
      fi
    '';

    ########################################################################
    # Hyprpaper: a single, deterministic source path (current.png)
    # Hyprland will "exec-once = hyprpaper &" and Hyprpaper will always
    # read ${cfgHome}/wallpapers/current.png (seeded below).
    ########################################################################
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      ipc = on
      splash = false
      preload = ${cfgHome}/wallpapers/current.png
      wallpaper = ,${cfgHome}/wallpapers/current.png
    '';

    # Seed default wallpapers declaratively:
    # - Copy repo’s nixos.png into ${cfgHome}/wallpapers if missing
    # - Link current.png -> nixos.png if current.png doesn’t exist yet
    home.activation.seedWallpapers = lib.hm.dag.entryAfter ["linkGeneration"] ''
      set -eu
      W="${cfgHome}/wallpapers"
      mkdir -p "$W"

      # Use the repository-provided default image as the baseline
      if [ ! -e "$W/nixos.png" ]; then
        # Install ensures correct perms and creates parent dirs if needed
        install -m 0644 -D "${hyprDir}/wallpapers/nixos.png" "$W/nixos.png" || true
      fi

      # Ensure a valid current.png exists so Hyprpaper never shows black on first login
      if [ ! -e "$W/current.png" ]; then
        ln -sfn "$W/nixos.png" "$W/current.png"
      fi
    '';

    ########################################################################
    # Make sure ~/.local/bin is part of PATH (for your CLI helpers, if any)
    ########################################################################
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

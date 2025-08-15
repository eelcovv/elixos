{
  config,
  pkgs,
  lib,
  ...
}: let
  # We ship one small helper script from ./scripts into ~/.local/bin
  scriptsDir = ./scripts;

  installScript = name: {
    ".local/bin/${name}" = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };
in {
  config = {
    ##########################################################################
    # Waybar — run it exactly once via systemd, bound to the Hyprland session
    #
    # Important:
    # - Do NOT start Waybar from hyprland.conf (no `exec`/`exec-once`).
    # - Wallpaper/theme switching is handled elsewhere (your scripts).
    ##########################################################################
    programs.waybar.enable = true;
    programs.waybar.package = pkgs.waybar;
    programs.waybar.systemd.enable = true;
    programs.waybar.systemd.target = "hyprland-session.target";

    ##########################################################################
    # Minimal, safe default config so Waybar can start even before any theme
    # switcher runs. This does not depend on your theme files.
    ##########################################################################
    xdg.configFile."waybar/config.jsonc".text = ''
      {
        "layer": "top",
        "position": "top",
        "height": 30,
        "modules-left": ["hyprland/workspaces", "hyprland/window"],
        "modules-center": ["clock"],
        "modules-right": ["tray", "pulseaudio", "battery"],
        "clock": { "format": "{:%H:%M}" },
        "hyprland/window": { "separate-outputs": true },
        "tray": { "icon-size": 18, "spacing": 8 }
      }
    '';

    # Provide an empty CSS file; your theme switcher can rewrite this later.
    xdg.configFile."waybar/style.css".text = ''
      /* placeholder; theme switcher will replace ~/.config/waybar/style.css */
    '';

    ##########################################################################
    # Install the theme switch wrapper into ~/.local/bin so you can call:
    #    waybar-switch-theme <theme> <variant>
    #
    # It delegates to switch_theme() from ~/.config/hypr/scripts/helper-functions.sh
    ##########################################################################
    home.file = lib.mkMerge [
      (installScript "waybar-switch-theme")
    ];

    ##########################################################################
    # Do NOT declare any wallpaper-related options here.
    # Wallpaper options live exclusively in: hyperland/waypaper/default.nix
    ##########################################################################
  };
}

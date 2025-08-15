{
  config,
  pkgs,
  lib,
  ...
}: let
  # Your script must live here:
  # home/modules/hyperland/waybar/scripts/waybar-switch-theme
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
    # Waybar — run exactly once via systemd, bound to the Hyprland session
    ##########################################################################
    programs.waybar.enable = true;
    programs.waybar.package = pkgs.waybar;
    programs.waybar.systemd.enable = true;
    programs.waybar.systemd.target = "hyprland-session.target";

    ##########################################################################
    # Minimal safe defaults so Waybar can start even before theming
    ##########################################################################
    xdg.configFile."waybar/config.jsonc".text = ''
      {
        "layer": "top",
        "position": "top",
        "height": 30,
        "modules-left":   ["hyprland/workspaces", "hyprland/window"],
        "modules-center": ["clock"],
        "modules-right":  ["tray", "pulseaudio", "battery"],
        "clock": { "format": "{:%H:%M}" },
        "hyprland/window": { "separate-outputs": true },
        "tray": { "icon-size": 18, "spacing": 8 }
      }
    '';
    xdg.configFile."waybar/style.css".text = "/* placeholder; theme switcher will update this */\n";

    ##########################################################################
    # Install the external script into ~/.local/bin
    ##########################################################################
    home.file = lib.mkMerge [
      (installScript "waybar-switch-theme")
    ];

    ##########################################################################
    # ⚠️ No wallpaper options here; they live in waypaper/default.nix
    ##########################################################################
  };
}

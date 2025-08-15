{
  config,
  pkgs,
  lib,
  ...
}: let
  scriptsDir = ./scripts;
  installScript = name: {
    ".local/bin/${name}" = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };
in {
  config = {
    programs.waybar.enable = true;
    programs.waybar.package = pkgs.waybar;
    programs.waybar.systemd.enable = true;
    programs.waybar.systemd.target = "hyprland-session.target";

    xdg.configFile."waybar/config.jsonc".text = ''
      { "layer": "top", "position": "top",
        "modules-left": ["hyprland/workspaces", "hyprland/window"],
        "modules-center": ["clock"],
        "modules-right": ["tray", "pulseaudio", "battery"],
        "clock": { "format": "{:%H:%M}" },
        "hyprland/window": { "separate-outputs": true },
        "tray": { "icon-size": 18, "spacing": 8 } }
    '';
    xdg.configFile."waybar/style.css".text = "/* placeholder */\n";

    home.file = lib.mkMerge [
      (installScript "waybar-switch-theme")
    ];
  };
}

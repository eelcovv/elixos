{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  scriptsDir = ./scripts;
in {
  config = {
    ##########################################################################
    # Waybar — managed by systemd, bound to Hyprland user target
    ##########################################################################
    programs.waybar.enable = true;
    programs.waybar.package = pkgs.waybar;
    programs.waybar.systemd.enable = true;
    programs.waybar.systemd.target = "hyprland-session.target";

    ##########################################################################
    # Global fallbacks so theme switchers never hit missing files
    ##########################################################################
    xdg.configFile."waybar/modules.jsonc".text = ''{ }'';
    xdg.configFile."waybar/colors.css".text = ''/* global fallback; themes usually override this */'';

    ##########################################################################
    # Expose your repo themes (read-only) into ~/.config/waybar/themes
    ##########################################################################
    xdg.configFile."waybar/themes".source = waybarDir + "/themes";

    ##########################################################################
    # Install Waybar switching scripts into ~/.local/bin
    ##########################################################################
    home.file.".local/bin/waybar-switch-theme" = {
      source = scriptsDir + "/waybar-switch-theme.sh";
      executable = true;
    };
    home.file.".local/bin/waybar-pick-theme" = {
      source = scriptsDir + "/waybar-pick-theme.sh";
      executable = true;
    };

    ##########################################################################
    # (Optional) Seed a placeholder file in current/ to avoid empty dir errors
    ##########################################################################
    # xdg.configFile."waybar/current/.keep".text = "";
  };
}

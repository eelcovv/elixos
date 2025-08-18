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
    #
    # Important:
    # - Do NOT start Waybar from hyprland.conf (no `exec`/`exec-once`).
    # - Systemd controls lifecycle; scripts only switch themes/configs.
    ##########################################################################
    programs.waybar.enable = true;
    programs.waybar.package = pkgs.waybar;

    # Tie Waybar to the Hyprland user target defined in hyperland/default.nix.
    programs.waybar.systemd.enable = true;
    programs.waybar.systemd.target = "hyprland-session.target";

    ##########################################################################
    # Global fallbacks so theme switchers never hit missing files
    ##########################################################################
    xdg.configFile."waybar/modules.jsonc".text = ''{ }'';
    xdg.configFile."waybar/colors.css".text = ''/* global fallback; themes usually override this */'';

    ##########################################################################
    # (Optional) Expose your theme tree from the repo (read-only)
    #
    # If you keep themes under this module (./themes), publish them to:
    #   ~/.config/waybar/themes
    # WARNING: Do not also manage individual files inside this directory.
    ##########################################################################
    # xdg.configFile."waybar/themes".source = waybarDir + "/themes";

    ##########################################################################
    # Install Waybar switching scripts into ~/.local/bin
    #
    # These scripts source ~/.config/hypr/scripts/helper-functions.sh which is
    # installed by the Hyprland module. They do NOT spawn Waybar; they only
    # rewrite links and trigger a systemd restart of Waybar.
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
    # (Optional) Seed an empty "current" dir placeholder (first boot)
    ##########################################################################
    # xdg.configFile."waybar/current/.keep".text = "";
  };
}

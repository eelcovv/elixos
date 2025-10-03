{ config, pkgs, lib, ... }:

{
  xdg.desktopEntries = {
    hyprshot-screen = {
      name = "Hyprshot (Screen)";
      genericName = "Screenshot";
      comment = "Capture the entire monitor";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh screen";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };

    hyprshot-region = {
      name = "Hyprshot (Region)";
      genericName = "Screenshot";
      comment = "Select a region to capture";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh region";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };

    hyprshot-window = {
      name = "Hyprshot (Window)";
      genericName = "Screenshot";
      comment = "Select a window to capture";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh window";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };

    hyprshot-selection = {
      name = "Hyprshot (Selection)";
      genericName = "Screenshot";
      comment = "Choose screenshot mode interactively";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh selection";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };
  };
}


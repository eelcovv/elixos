{
  config,
  pkgs,
  lib,
  ...
}: {
  # Deploy scripts uit je repo naar ~/.config/hypr/scripts/
  home.file."${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh".source =
    ./scripts/wayland-screenshot.sh;
  home.file."${config.xdg.configHome}/hypr/scripts/wayland-screenshot-picker.sh".source =
    ./scripts/wayland-screenshot-picker.sh;

  # (optioneel) maak ze uitvoerbaar als je repo ze niet al +x heeft
  home.activation."chmod-hypr-screenshot-scripts" = lib.hm.dag.entryAfter ["writeBoundary"] ''
    chmod +x "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh"
    chmod +x "${config.xdg.configHome}/hypr/scripts/wayland-screenshot-picker.sh"
  '';

  xdg.desktopEntries = {
    # --- jouw hyprshot entries (ongewijzigd behalve gequote keys) ---
    "hyprshot-screen" = {
      name = "Hyprshot (Screen)";
      genericName = "Screenshot";
      comment = "Capture the entire monitor";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh screen";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Utility" "Graphics"];
    };
    "hyprshot-region" = {
      name = "Hyprshot (Region)";
      genericName = "Screenshot";
      comment = "Select a region to capture";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh region";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Utility" "Graphics"];
    };
    "hyprshot-window" = {
      name = "Hyprshot (Window)";
      genericName = "Screenshot";
      comment = "Select a window to capture";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh window";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Utility" "Graphics"];
    };
    "hyprshot-selection" = {
      name = "Hyprshot (Selection)";
      genericName = "Screenshot";
      comment = "Choose screenshot mode interactively";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh selection";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Utility" "Graphics"];
    };

    # --- grim+slurp entries (zonder 'keywords') ---
    "wayland-screenshot-picker" = {
      name = "Wayland Screenshot (Picker)";
      genericName = "Screenshot";
      comment = "Capture screenshots via grim+slurp (picker)";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot-picker.sh";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-area-clipboard" = {
      name = "Screenshot (Area -> Clipboard)";
      comment = "Capture a region to clipboard";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh area-clipboard";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-area-save" = {
      name = "Screenshot (Area -> Save)";
      comment = "Capture a region and save as PNG";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh area-save";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-area-annotate" = {
      name = "Screenshot (Area -> Annotate, swappy)";
      comment = "Capture a region and annotate with swappy";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh area-annotate";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-area-annotate-satty" = {
      name = "Screenshot (Area -> Annotate, satty)";
      comment = "Capture a region and annotate with satty";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh area-annotate-satty";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-full-save" = {
      name = "Screenshot (Full -> Save)";
      comment = "Capture the full screen and save as PNG";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh full-save";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-full-clipboard" = {
      name = "Screenshot (Full -> Clipboard)";
      comment = "Capture the full screen to clipboard";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh full-clipboard";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}: {
  # Deploy scripts naar ~/.config/hypr/scripts/ en maak ze uitvoerbaar (zonder chmod-activation)
  home.file."${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh" = {
    text = builtins.readFile ./scripts/wayland-screenshot.sh;
    executable = true;
  };

  # Vervang '->' door '→' in het picker-script voor mooie labels
  home.file."${config.xdg.configHome}/hypr/scripts/wayland-screenshot-picker.sh" = {
    text =
      lib.replaceStrings
      ["Area -> Save (PNG)" "Area -> Clipboard" "Area -> Annotate (swappy)" "Area -> Annotate (satty)" "Full -> Save (PNG)" "Full -> Clipboard"]
      ["Area → Save (PNG)" "Area → Clipboard" "Area → Annotate (swappy)" "Area → Annotate (satty)" "Full → Save (PNG)" "Full → Clipboard"]
      (builtins.readFile ./scripts/wayland-screenshot-picker.sh);
    executable = true;
  };

  # Desktop entries: ongewijzigd behalve dat ze al naar deze scripts wijzen
  xdg.desktopEntries = {
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
      name = "Screenshot (Area → Clipboard)";
      comment = "Capture a region to clipboard";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh area-clipboard";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-area-save" = {
      name = "Screenshot (Area → Save)";
      comment = "Capture a region and save as PNG";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh area-save";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-area-annotate" = {
      name = "Screenshot (Area → Annotate, swappy)";
      comment = "Capture a region and annotate with swappy";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh area-annotate";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-area-annotate-satty" = {
      name = "Screenshot (Area → Annotate, satty)";
      comment = "Capture a region and annotate with satty";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh area-annotate-satty";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-full-save" = {
      name = "Screenshot (Full → Save)";
      comment = "Capture the full screen and save as PNG";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh full-save";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
    "wayland-screenshot-full-clipboard" = {
      name = "Screenshot (Full → Clipboard)";
      comment = "Capture the full screen to clipboard";
      exec = "${config.xdg.configHome}/hypr/scripts/wayland-screenshot.sh full-clipboard";
      icon = "applets-screenshooter";
      terminal = false;
      categories = ["Graphics" "Utility"];
    };
  };
}

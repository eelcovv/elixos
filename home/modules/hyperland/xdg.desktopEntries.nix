{ config, pkgs, lib, ... }:
let
  waylandScreenshot = pkgs.writeShellApplication {
    name = "wayland-screenshot";
    runtimeInputs = with pkgs; [ grim slurp wl-clipboard swappy satty ];
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      DIR="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
      mkdir -p "$DIR"

      timestamp() { date +'%Y-%m-%d_%H-%M-%S'; }
      file_png="$DIR/screenshot_$(timestamp).png"

      notify() {
        command -v notify-send >/dev/null 2>&1 || return 0
        notify-send -a "Screenshot" "$1" "$2" || true
      }

      cmd="${1:-}"
      case "$cmd" in
        area-save)
          grim -g "$(slurp)" "$file_png"
          notify "Saved" "$file_png"
          echo "$file_png"
          ;;
        area-clipboard)
          grim -g "$(slurp)" - | wl-copy --type image/png
          notify "Copied to clipboard" "Selection captured"
          ;;
        area-annotate)
          grim -g "$(slurp)" - | swappy -f -
          ;;
        area-annotate-satty)
          if command -v satty >/dev/null 2>&1; then
            grim -g "$(slurp)" - | satty -f - --copy-command wl-copy
          else
            grim -g "$(slurp)" - | swappy -f -
          fi
          ;;
        full-save)
          grim "$file_png"
          notify "Saved" "$file_png"
          echo "$file_png"
          ;;
        full-clipboard)
          grim - | wl-copy --type image/png
          notify "Copied to clipboard" "Full screen captured"
          ;;
        *)
          echo "Usage: $0 {area-save|area-clipboard|area-annotate|area-annotate-satty|full-save|full-clipboard}" >&2
          exit 2
          ;;
      esac
    '';
  };

  screenshotPicker = pkgs.writeShellApplication {
    name = "screenshot-picker";
    runtimeInputs = with pkgs; [ rofi wofi waylandScreenshot ];
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      PICKER=""
      if command -v rofi >/dev/null 2>&1; then
        PICKER="rofi -dmenu -p Screenshot"
      elif command -v wofi >/dev/null 2>&1; then
        PICKER="wofi --dmenu -p Screenshot"
      else
        echo "No rofi/wofi found." >&2
        exit 1
      fi

      options=(
        "Area -> Save (PNG):::wayland-screenshot area-save"
        "Area -> Clipboard:::wayland-screenshot area-clipboard"
        "Area -> Annotate (swappy):::wayland-screenshot area-annotate"
        "Area -> Annotate (satty):::wayland-screenshot area-annotate-satty"
        "Full -> Save (PNG):::wayland-screenshot full-save"
        "Full -> Clipboard:::wayland-screenshot full-clipboard"
      )

      label_list=$(printf '%s\n' "${options[@]}" | cut -d':::' -f1)
      choice=$(echo "$label_list" | eval "$PICKER") || exit 0
      cmd=$(printf '%s\n' "${options[@]}" | grep -F "$choice" | head -n1 | cut -d':::' -f2-)
      exec bash -lc "$cmd"
    '';
  };
in
{
  home.packages = with pkgs; [
    grim slurp wl-clipboard swappy satty rofi wofi
  ];

  xdg.desktopEntries = {
    # Bestaande hyprshot-entries — let op: keys met '-' nu gequote
    "hyprshot-screen" = {
      name = "Hyprshot (Screen)";
      genericName = "Screenshot";
      comment = "Capture the entire monitor";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh screen";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };

    "hyprshot-region" = {
      name = "Hyprshot (Region)";
      genericName = "Screenshot";
      comment = "Select a region to capture";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh region";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };

    "hyprshot-window" = {
      name = "Hyprshot (Window)";
      genericName = "Screenshot";
      comment = "Select a window to capture";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh window";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };

    "hyprshot-selection" = {
      name = "Hyprshot (Selection)";
      genericName = "Screenshot";
      comment = "Choose screenshot mode interactively";
      exec = "${config.xdg.configHome}/hypr/scripts/hyprshot-launcher.sh selection";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };

    # Nieuwe grim+slurp entries — keys gequote
    "wayland-screenshot-picker" = {
      name = "Wayland Screenshot (Picker)";
      genericName = "Screenshot";
      comment = "Capture screenshots via grim+slurp (picker)";
      exec = "${screenshotPicker}/bin/screenshot-picker";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Graphics" "Utility" ];
      keywords = [ "screenshot" "screen" "capture" "wayland" "grim" "slurp" ];
    };

    "wayland-screenshot-area-clipboard" = {
      name = "Screenshot (Area -> Clipboard)";
      comment = "Capture a region to clipboard";
      exec = "${waylandScreenshot}/bin/wayland-screenshot area-clipboard";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Graphics" "Utility" ];
    };

    "wayland-screenshot-area-save" = {
      name = "Screenshot (Area -> Save)";
      comment = "Capture a region and save as PNG";
      exec = "${waylandScreenshot}/bin/wayland-screenshot area-save";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Graphics" "Utility" ];
    };

    "wayland-screenshot-area-annotate" = {
      name = "Screenshot (Area -> Annotate, swappy)";
      comment = "Capture a region and annotate with swappy";
      exec = "${waylandScreenshot}/bin/wayland-screenshot area-annotate";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Graphics" "Utility" ];
    };

    "wayland-screenshot-area-annotate-satty" = {
      name = "Screenshot (Area -> Annotate, satty)";
      comment = "Capture a region and annotate with satty";
      exec = "${waylandScreenshot}/bin/wayland-screenshot area-annotate-satty";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Graphics" "Utility" ];
    };

    "wayland-screenshot-full-save" = {
      name = "Screenshot (Full -> Save)";
      comment = "Capture the full screen and save as PNG";
      exec = "${waylandScreenshot}/bin/wayland-screenshot full-save";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Graphics" "Utility" ];
    };

    "wayland-screenshot-full-clipboard" = {
      name = "Screenshot (Full -> Clipboard)";
      comment = "Capture the full screen to clipboard";
      exec = "${waylandScreenshot}/bin/wayland-screenshot full-clipboard";
      icon = "applets-screenshooter";
      terminal = false;
      categories = [ "Graphics" "Utility" ];
    };
  };
}


{ config, pkgs, lib, ... }:

let
  # --- Script sources (exact zoals jij ze aanleverde, met mini-fix voor library.sh) ---
  library_sh = ''
    #!/usr/bin/env bash
    # Minimal shared logger used by wallpaper scripts
    _writeLog() {
      echo ":: $*"
    }
  '';

  wallpaper_sh = lib.replaceStrings
    [ 'source "./library.sh"' ]
    [ 'source "$HOME/.config/hypr/scripts/library.sh"' ]
    ''
#!/usr/bin/env bash
#  _      __     ____                      
# | | /| / /__ _/ / /__  ___ ____  ___ ____
# | |/ |/ / _ `/ / / _ \/ _ `/ _ \/ -_) __/
# |__/|__/\_,_/_/_/ .__/\_,_/ .__/\__/_/   
#                /_/       /_/             

set -euo pipefail

# -----------------------------------------------------
# Source shared logging functions
# -----------------------------------------------------

source "$HOME/.config/hypr/scripts/library.sh"

# -----------------------------------------------------
# Wallpaper cache control
# -----------------------------------------------------

use_cache=0
if [[ -f "$HOME/.config/hypr/settings/wallpaper_cache" ]]; then
    use_cache=1
    _writeLog "Using Wallpaper Cache"
else
    _writeLog "Wallpaper Cache disabled"
fi

# -----------------------------------------------------
# Prepare folders
# -----------------------------------------------------

hypr_cache_folder="$HOME/.cache/hyprlock-assets"
mkdir -p "$hypr_cache_folder"

generatedversions="$hypr_cache_folder/wallpaper-generated"
mkdir -p "$generatedversions"

waypaperrunning="$hypr_cache_folder/waypaper-running"
[[ -f "$waypaperrunning" ]] && rm "$waypaperrunning" && exit

# -----------------------------------------------------
# Set defaults and paths
# -----------------------------------------------------

force_generate=0
cachefile="$hypr_cache_folder/current_wallpaper"
blurredwallpaper="$hypr_cache_folder/blurred_wallpaper.png"
squarewallpaper="$hypr_cache_folder/square_wallpaper.png"
rasifile="$hypr_cache_folder/current_wallpaper.rasi"
blurfile="$HOME/.config/hypr/settings/blur.sh"
defaultwallpaper="$HOME/.config/wallpapers/default.jpg"
wallpapereffect="$HOME/.config/hypr/settings/wallpaper-effect.sh"
blur="50x30"

[[ -f "$blurfile" ]] && blur="$(<"$blurfile")"

# -----------------------------------------------------
# Determine wallpaper
# -----------------------------------------------------

if [[ "${1:-}" == "" ]]; then
    wallpaper="${defaultwallpaper}"
    [[ -f "$cachefile" ]] && wallpaper="$(<"$cachefile")"
else
    wallpaper="$1"
fi

used_wallpaper="$wallpaper"
_writeLog "Setting wallpaper with source image $wallpaper"
tmpwallpaper="$wallpaper"

echo "$wallpaper" > "$cachefile"
_writeLog "Path of current wallpaper copied to $cachefile"

wallpaperfilename="$(basename "$wallpaper")"
_writeLog "Wallpaper Filename: $wallpaperfilename"

# -----------------------------------------------------
# Wallpaper Effects
# -----------------------------------------------------

effect="off"
if [[ -f "$wallpapereffect" ]]; then
    effect="$(<"$wallpapereffect")"
    if [[ "$effect" != "off" ]]; then
        used_wallpaper="$generatedversions/$effect-$wallpaperfilename"
        if [[ -f "$used_wallpaper" && "$force_generate" == "0" && "$use_cache" == "1" ]]; then
            _writeLog "Use cached wallpaper $effect-$wallpaperfilename"
        else
            _writeLog "Generate new cached wallpaper $effect-$wallpaperfilename with effect $effect"
            notify-send --replace-id=1 "Using wallpaper effect $effect..." "with image $wallpaperfilename" -h int:value:33
            source "$HOME/.config/hypr/effects/wallpaper/$effect"
        fi
        _writeLog "Setting wallpaper with $used_wallpaper"
        touch "$waypaperrunning"
        waypaper --wallpaper "$used_wallpaper"
    else
        _writeLog "Wallpaper effect is set to off"
    fi
fi

# -----------------------------------------------------
# Execute matugen and wallust
# -----------------------------------------------------

_writeLog "Execute matugen with $used_wallpaper"
"$HOME/.local/bin/matugen" image "$used_wallpaper" -m "dark"

_writeLog "Execute wallust with $used_wallpaper"
"$HOME/.local/bin/wallust" run "$used_wallpaper"

# -----------------------------------------------------
# Reload bar/dock/notifications
# -----------------------------------------------------

sleep 1
"$HOME/.config/waybar/launch.sh" || true
"$HOME/.config/nwg-dock-hyprland/launch.sh" &>/dev/null &

if command -v pywalfox &>/dev/null; then
    pywalfox update || true
fi

sleep 0.1
command -v swaync-client &>/dev/null && swaync-client -rs || true

# -----------------------------------------------------
# Generate blurred wallpaper
# -----------------------------------------------------

blurred_cache="$generatedversions/blur-$blur-$effect-$wallpaperfilename.png"

if [[ -f "$blurred_cache" && "$force_generate" == "0" && "$use_cache" == "1" ]]; then
    _writeLog "Use cached blurred wallpaper $blurred_cache"
else
    _writeLog "Generating blurred wallpaper with blur $blur"
    magick "$used_wallpaper" -resize 75% "$blurredwallpaper"
    [[ "$blur" != "0x0" ]] && magick "$blurredwallpaper" -blur "$blur" "$blurredwallpaper"
    cp "$blurredwallpaper" "$blurred_cache"
fi

cp "$blurred_cache" "$blurredwallpaper"

# -----------------------------------------------------
# Create .rasi preview for rofi
# -----------------------------------------------------

echo "* { current-image: url(\"$blurredwallpaper\", height); }" > "$rasifile"

# -----------------------------------------------------
# Create square-cropped wallpaper
# -----------------------------------------------------

_writeLog "Generating square-cropped wallpaper $squarewallpaper"
magick "$tmpwallpaper" -gravity Center -extent 1:1 "$squarewallpaper"
cp "$squarewallpaper" "$generatedversions/square-$wallpaperfilename.png"
    '';

  wallpaper_restore_sh = ''
#!/usr/bin/env bash
set -euo pipefail

hypr_cache_folder="$HOME/.cache/hyprlock-assets"
default_wallpaper="$HOME/.config/wallpapers/default.jpg"
cache_file="$hypr_cache_folder/current_wallpaper"

if [[ -f "$cache_file" ]]; then
    sed -i "s|~|$HOME|g" "$cache_file"
    wallpaper=$(<"$cache_file")
    if [[ ! -f "$wallpaper" ]]; then
        echo ":: Wallpaper $wallpaper does not exist. Using default."
        wallpaper="$default_wallpaper"
    else
        echo ":: Wallpaper $wallpaper exists"
    fi
else
    echo ":: $cache_file does not exist. Using default wallpaper."
    wallpaper="$default_wallpaper"
fi

echo ":: Setting wallpaper with source image: $wallpaper"

# Add local waypaper if present
if [[ -x "$HOME/.local/bin/waypaper" ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

waypaper --wallpaper "$wallpaper"
  '';

  wallpaper_effects_sh = ''
#!/usr/bin/env bash
set -euo pipefail

hypr_cache_folder="$HOME/.cache/hyprlock-assets"
cache_file="$hypr_cache_folder/current_wallpaper"
effect_file="$HOME/.config/hypr/settings/wallpaper-effect.sh"
effects_dir="$HOME/.config/hypr/effects/wallpaper"
rofi_config="$HOME/.config/rofi/config-themes.rasi"

if [[ "${1:-}" == "reload" ]]; then
    if [[ -f "$cache_file" ]]; then
        waypaper --wallpaper "$(cat "$cache_file")"
    else
        notify-send "Wallpaper Effect" "No cached wallpaper found."
        exit 1
    fi
else
    options="$(ls "$effects_dir" 2>/dev/null || true)"$'\n'"off"
    choice=$(echo -e "$options" | rofi -dmenu -replace -config "$rofi_config" -i -no-show-icons -l 5 -width 30 -p "Hyprshade")

    if [[ -n "${choice:-}" ]]; then
        echo "$choice" > "$effect_file"
        notify-send "Changing Wallpaper Effect" "$choice"

        if [[ -f "$cache_file" ]]; then
            waypaper --wallpaper "$(cat "$cache_file")"
        else
            notify-send "Wallpaper Effect" "No cached wallpaper found."
            exit 1
        fi
    fi
fi
  '';

  wallpaper_cache_sh = ''
#!/usr/bin/env bash
set -euo pipefail
hypr_cache_folder="$HOME/.cache/hyprlock-assets"
generated_versions="$hypr_cache_folder/wallpaper-generated"
mkdir -p "$generated_versions"
rm -f "$generated_versions"/* 2>/dev/null || true
echo ":: Wallpaper cache cleared"
notify-send "Wallpaper cache cleared"
  '';

  wallpaper_automation_sh = ''
#!/usr/bin/env bash
set -euo pipefail

wallpaper_dir="$HOME/.config/hypr/wallpapers"
automation_flag="$HOME/.cache/hyprlock-assets/wallpaper-automation"
interval_file="$HOME/.config/hypr/settings/wallpaper-automation.sh"

mkdir -p "$(dirname "$automation_flag")" "$wallpaper_dir" "$(dirname "$interval_file")"

if [ ! -f "$interval_file" ]; then
    echo "60" > "$interval_file"
fi

sec=$(cat "$interval_file")

_setWallpaperRandomly() {
    waypaper --random
    echo ":: Next wallpaper in $sec seconds..."
    sleep "$sec"
    _setWallpaperRandomly
}

if [ ! -f "$automation_flag" ]; then
    touch "$automation_flag"
    notify-send "Wallpaper automation started" "Wallpaper will change every $sec seconds."
    _setWallpaperRandomly
else
    rm -f "$automation_flag"
    notify-send "Wallpaper automation stopped."
    pkill -f wallpaper-automation.sh || true
fi
  '';

  fetch_wallpapers_sh = ''
#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/.config/wallpapers"
REPO_URL="https://github.com/mylinuxforwork/wallpaper"
TMP_DIR="$(mktemp -d)"

echo "📥 Downloading wallpapers from $REPO_URL..."
git clone --depth=1 "$REPO_URL" "$TMP_DIR"

mkdir -p "$WALLPAPER_DIR"
find "$TMP_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" \) -exec cp {} "$WALLPAPER_DIR/" \;

echo "✅ Wallpapers downloaded to $WALLPAPER_DIR"
rm -rf "$TMP_DIR"
  '';

  # --- Default config files (kunnen later door jou worden overschreven) ---
  default_effect = "off\n";
  default_blur = "50x30\n";
  default_automation_interval = "60\n";
  default_rofi_themes = ''
/* Minimal rofi config used by wallpaper-effects.sh */
configuration {
  modi: "drun,run";
  font: "Inter 12";
  show-icons: false;
}
  '';
in
{
  options = {
    hyprland.wallpaper.enable = lib.mkEnableOption "Enable Hyprland wallpaper tools";
  };

  config = lib.mkIf config.hyprland.wallpaper.enable {
    # Benodigde tools
    home.packages = with pkgs; [
      waypaper
      imagemagick
      wallust
      matugen
      rofi-wayland
      libnotify
      swaynotificationcenter
      git
      # optioneel:
      nwg-dock-hyprland
      (python3.withPackages (ps: [ ps.pywalfox ]))
    ];

    # Scripts naar ~/.local/bin
    home.file.".local/bin/wallpaper.sh" = { text = wallpaper_sh; executable = true; };
    home.file.".local/bin/wallpaper-restore.sh" = { text = wallpaper_restore_sh; executable = true; };
    home.file.".local/bin/wallpaper-effects.sh" = { text = wallpaper_effects_sh; executable = true; };
    home.file.".local/bin/wallpaper-cache.sh" = { text = wallpaper_cache_sh; executable = true; };
    home.file.".local/bin/wallpaper-automation.sh" = { text = wallpaper_automation_sh; executable = true; };
    home.file.".local/bin/fetch-wallpapers.sh" = { text = fetch_wallpapers_sh; executable = true; };

    # Gedeelde library
    home.file.".config/hypr/scripts/library.sh" = { text = library_sh; executable = true; };

    # Config en defaults
    home.file.".config/hypr/settings/wallpaper-effect.sh".text = lib.mkDefault default_effect;
    home.file.".config/hypr/settings/blur.sh".text = lib.mkDefault default_blur;
    home.file.".config/hypr/settings/wallpaper-automation.sh".text = lib.mkDefault default_automation_interval;
    home.file.".config/rofi/config-themes.rasi".text = lib.mkDefault default_rofi_themes;

    # Zorg voor mappen die de scripts verwachten
    home.file.".config/wallpapers/.keep".text = "";
    home.file.".config/hypr/effects/wallpaper/.keep".text = "";
    home.file.".cache/hyprlock-assets/.keep".text = "";

    # Optioneel: systemd user-service voor automation (robuster dan self-loop)
    systemd.user.services."wallpaper-automation" = {
      Unit = {
        Description = "Hypr wallpaper automation (random via waypaper)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${config.home.homeDirectory}/.local/bin/wallpaper-automation.sh";
        Restart = "on-failure";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };

    # (Niet automatisch enabled; toggle zelf via script óf enable hier)
    # systemd.user.services."wallpaper-automation".Install.WantedBy = [ "default.target" ];
  };
}


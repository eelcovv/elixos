{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  themesDir = ./themes;

  cfgPath = "${config.xdg.configHome}/waybar";

  waitForHypr = pkgs.writeShellScript "wait-for-hypr" ''
    for i in $(seq 1 50); do
      if ${pkgs.hyprland}/bin/hyprctl -j monitors >/dev/null 2>&1; then
        exit 0
      fi
      sleep 0.1
    done
    exit 0
  '';
in {
  config = {
    programs.waybar.enable = true;
    programs.waybar.package = pkgs.waybar;
    # We beheren Waybar via onze eigen user service hieronder:
    programs.waybar.systemd.enable = false;

    home.packages = with pkgs; [
      pavucontrol
      pamixer
      wlogout
      blueman
      networkmanagerapplet
      jq
      gnome-calculator
      qalculate-gtk
      wofi
      wl-clipboard
      playerctl
      bc
      htop
    ];

    # ---------------------------
    # Waybar (managed) user service
    # ---------------------------
    systemd.user.services."waybar-managed" = {
      Unit = {
        Description = "Waybar (managed by Home Manager; uses ~/.config/waybar/{config,style.css})";
        After = ["graphical-session.target" "hyprland-session.target" "hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
        Conflicts = ["waybar.service"];
      };
      Service = {
        Type = "simple";
        # belangrijk: runtime dir voor user services
        Environment = ["XDG_RUNTIME_DIR=%t"];
        ExecStartPre = [
          "${waitForHypr}"
          "${pkgs.coreutils}/bin/sleep 0.25"
        ];
        # zelfde paden als je cli die werkt
        ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config -s ${cfgPath}/style.css";
        Restart = "on-failure";
        RestartSec = "1s";
        # optioneel: forceer logging naar journal (meestal default, kan helpen)
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = ["hyprland-session.target"];
    };

    # ---------------------------
    # Script: waybar-hypridle (naar ~/.local/bin)
    # ---------------------------
    home.file.".local/bin/waybar-hypridle" = {
      source = waybarDir + "/scripts/waybar-hypridle.sh";
      executable = true;
    };

    # ---------------------------
    # Thema’s (read-only uit de store)
    # ---------------------------
    xdg.configFile."waybar/themes".source = themesDir;
    xdg.configFile."waybar/themes".recursive = true;

    # ---------------------------
    # Seed: schrijfbare user-files (eenmalig)
    # ---------------------------
    home.activation.ensureWaybarSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -eu
      cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
      mkdir -p "$cfg_dir"

      if [ ! -f "$cfg_dir/config.jsonc" ]; then
        install -Dm0644 "${themesDir}/default/config.jsonc" "$cfg_dir/config.jsonc"
      fi
      if [ ! -f "$cfg_dir/style.css" ]; then
        install -Dm0644 "${themesDir}/default/style.css" "$cfg_dir/style.css"
      fi
      if [ ! -f "$cfg_dir/colors.css" ]; then
        printf '/* default colors */\n' >"$cfg_dir/colors.css"
        chmod 0644 "$cfg_dir/colors.css"
      fi
      if [ ! -f "$cfg_dir/modules.jsonc" ]; then
        printf '{}\n' >"$cfg_dir/modules.jsonc"
        chmod 0644 "$cfg_dir/modules.jsonc"
      fi
      if [ ! -f "$cfg_dir/waybar-quicklinks.json" ]; then
        printf '[]\n' >"$cfg_dir/waybar-quicklinks.json"
        chmod 0644 "$cfg_dir/waybar-quicklinks.json"
      fi

      # Compat-symlink zodat -c ${cfgPath}/config het JSONC-bestand gebruikt
      ln -sfn "$cfg_dir/config.jsonc" "$cfg_dir/config"
    '';

    # ---------------------------
    # Declaratieve inhoud: modules & quicklinks
    # ---------------------------
    xdg.configFile."waybar/modules.jsonc".text = ''
      {
        "hyprland/workspaces": {
          "on-scroll-up": "hyprctl dispatch workspace r-1",
          "on-scroll-down": "hyprctl dispatch workspace r+1",
          "on-click": "activate",
          "active-only": false,
          "all-outputs": true,
          "format": "{}",
          "format-icons": { "urgent": "", "active": "", "default": "" },
          "persistent-workspaces": { "*": 5 }
        },

        "wlr/taskbar": {
          "format": "{icon}",
          "icon-size": 18,
          "tooltip-format": "{title}",
          "on-click": "activate",
          "on-click-middle": "close",
          "ignore-list": ["Alacritty", "kitty"],
          "app_ids-mapping": { "firefoxdeveloperedition": "firefox-developer-edition" },
          "rewrite": { "Firefox Web Browser": "Firefox", "Foot Server": "Terminal" }
        },

        "hyprland/window": {
          "max-length": 60,
          "rewrite": {
            "(.*) - Brave": "$1",
            "(.*) - Chromium": "$1",
            "(.*) - Brave Search": "$1",
            "(.*) - Outlook": "$1",
            "(.*) Microsoft Teams": "$1"
          },
          "separate-outputs": true
        },

        "custom/empty": { "format": "" },
        "custom/tools": { "format": "", "tooltip-format": "Tools" },

        "custom/cliphist": {
          "format": "",
          "on-click": "sleep 0.1 && ~/.config/hypr/scripts/cliphist.sh",
          "on-click-right": "sleep 0.1 && ~/.config/hypr/scripts/cliphist.sh d",
          "on-click-middle": "sleep 0.1 && ~/.config/hypr/scripts/cliphist.sh w",
          "tooltip-format": "Left: Open clipboard Manager\\nRight: Delete an entry\\nMiddle: Clear list"
        },

        "custom/wallpaper": {
          "format": "",
          "on-click": "bash -c waypaper &",
          "on-click-right": "~/.config/hypr/scripts/wallpaper-effects.sh",
          "tooltip-format": "Left: Select a wallpaper\\nRight: Select wallpaper effect"
        },

        "custom/waybarthemes": {
          "format": "",
          "on-click": "~/.local/bin/waybar-pick-theme",
          "tooltip-format": "Select a waybar theme"
        },

        "custom/appmenu": {
          "format": "Apps",
          "on-click": "sleep 0.2;pkill rofi || rofi -show drun -replace",
          "on-click-right": "~/.config/hypr/scripts/keybindings.sh",
          "tooltip-format": "Left: Open the application launcher\\nRight: Show all keybindings"
        },

        "custom/appmenuicon": {
          "format": "",
          "on-click": "sleep 0.2;rofi -show drun -replace",
          "on-click-right": "~/.config/hypr/scripts/keybindings.sh",
          "tooltip-format": "Left: Open the application launcher\\nRight: Show all keybindings"
        },

        "custom/exit": {
          "format": "",
          "on-click": "~/.config/hypr/scripts/wlogout.sh",
          "on-click-right": "hyprlock",
          "tooltip-format": "Left: Power menu\\nRight: Lock screen"
        },

        "custom/notification": {
          "tooltip-format": "Left: Notifications\\nRight: Do not disturb",
          "format": "{icon}",
          "format-icons": {
            "notification": "<span rise='8pt'><span foreground='red'><sup></sup></span></span>",
            "none": "",
            "dnd-notification": "<span rise='8pt'><span foreground='red'><sup></sup></span></span>",
            "dnd-none": "",
            "inhibited-notification": "<span rise='8pt'><span foreground='red'><sup></sup></span></span>",
            "inhibited-none": "",
            "dnd-inhibited-notification": "<span rise='8pt'><span foreground='red'><sup></sup></span></span>"
          },
          "return-type": "json",
          "exec-if": "which swaync-client",
          "exec": "swaync-client -swb",
          "on-click": "swaync-client -t -sw",
          "on-click-right": "swaync-client -d -sw",
          "escape": true
        },

        "custom/hypridle": {
          "return-type": "json",
          "interval": 5,
          "exec": "~/.local/bin/waybar-hypridle",
          "on-click": "hyprctl dispatch dpms off",
          "tooltip": true
        },

        "keyboard-state": {
          "numlock": true,
          "capslock": true,
          "format": "{name} {icon}",
          "format-icons": { "locked": "", "unlocked": "" }
        },

        "tray": { "icon-size": 21, "spacing": 10 },

        "clock": { "format": "{:%H:%M %a}", "on-click": "flatpak run com.ml4w.calendar", "timezone": "", "tooltip": false },

        "custom/system": { "format": "", "tooltip": false },

        "cpu": { "format": "/ C {usage}% ", "on-click": "~/.local/bin/system-monitor" },
        "memory": { "format": "/ M {}% ", "on-click": "~/.local/bin/system-monitor" },
        "disk": {
          "interval": 30,
          "format": "D {percentage_used}% ",
          "path": "/",
          "on-click": "~/.local/bin/system-monitor"
        },

        "hyprland/language": { "format": "/ K {short}" },

        "group/hardware": {
          "orientation": "inherit",
          "drawer": { "transition-duration": 300, "children-class": "not-memory", "transition-left-to-right": false },
          "modules": [ "custom/system", "disk", "cpu", "memory", "hyprland/language" ]
        },

        "group/tools": {
          "orientation": "inherit",
          "drawer": { "transition-duration": 300, "children-class": "not-memory", "transition-left-to-right": false },
          "modules": [ "custom/tools", "custom/cliphist", "custom/hypridle", "custom/hyprshade" ]
        },

        "group/links": {
          "orientation": "horizontal",
          "modules": [ "custom/chatgpt", "custom/empty" ]
        },

        "group/settings": {
          "orientation": "inherit",
          "drawer": { "transition-duration": 300, "children-class": "not-memory", "transition-left-to-right": true },
          "modules": [ "custom/settings", "custom/waybarthemes", "custom/wallpaper" ]
        },

        "network": {
          "format": "{ifname}",
          "format-wifi": " {essid} ({signalStrength}%)",
          "format-ethernet": "  {ifname}",
          "format-disconnected": "Disconnected ⚠",
          "tooltip-format": " {ifname} via {gwaddri}",
          "tooltip-format-wifi": "  {ifname} @ {essid}\\nIP: {ipaddr}\\nStrength: {signalStrength}%\\nFreq: {frequency}MHz\\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}",
          "tooltip-format-ethernet": " {ifname}\\nIP: {ipaddr}\\n up: {bandwidthUpBits} down: {bandwidthDownBits}",
          "tooltip-format-disconnected": "Disconnected",
          "max-length": 50,
          "on-click": "~/.config/hypr/scripts/nm-applet.sh toggle",
          "on-click-right": "~/.config/hypr/scripts/nm-applet.sh stop"
        },

        "battery": {
          "states": { "warning": 30, "critical": 15 },
          "format": "{icon} {capacity}%",
          "format-charging": "  {capacity}%",
          "format-plugged": "  {capacity}%",
          "format-alt": "{icon}  {time}",
          "format-icons": [ " ", " ", " ", " ", " " ]
        },

        "power-profiles-daemon": {
          "format": "{icon}",
          "tooltip-format": "Power profile: {profile}\\nDriver: {driver}",
          "tooltip": true,
          "format-icons": { "default": "", "performance": "", "balanced": "", "power-saver": "" }
        },

        "pulseaudio": {
          "format": "{icon}  {volume}%",
          "format-bluetooth": "{volume}% {icon} {format_source}",
          "format-bluetooth-muted": " {icon} {format_source}",
          "format-muted": " {format_source}",
          "format-source": "{volume}% ",
          "format-source-muted": "",
          "format-icons": {
            "headphone": " ",
            "hands-free": " ",
            "headset": " ",
            "phone": " ",
            "portable": " ",
            "car": " ",
            "default": [ "", "", "" ]
          },
          "on-click": "pavucontrol"
        },

        "bluetooth": {
          "format": " {status}",
          "format-disabled": "",
          "format-off": "",
          "interval": 30,
          "on-click": "blueman-manager",
          "format-no-controller": ""
        },

        "user": { "format": "{user}", "interval": 60, "icon": false },

        "backlight": {
          "format": "{icon} {percent}%",
          "format-icons": [ "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" ],
          "scroll-step": 1
        }
      }
    '';

    xdg.configFile."waybar/waybar-quicklinks.json".text = ''
      {
        "custom/quicklink_browser": { "format": "", "on-click": "google-chrome-stable", "tooltip-format": "Open Browser" },
        "custom/quicklink_filemanager": { "format": "", "on-click": "nautilus", "tooltip-format": "Open Filemanager" },
        "custom/quicklink_email": { "format": "", "on-click": "thunderbird", "tooltip-format": "Open Email Client" },
        "custom/quicklinkempty": {},
        "group/quicklinks": {
          "orientation": "horizontal",
          "modules": [ "custom/quicklink_browser", "custom/quicklink_email", "custom/quicklink_filemanager", "custom/quicklinkempty" ]
        }
      }
    '';

    # ---------------------------
    # Kleine helper via modules
    # ---------------------------
    home.file.".local/bin/system-monitor" = {
      text = ''
        #!/usr/bin/env bash
        if command -v gnome-system-monitor >/dev/null 2>&1; then
          exec gnome-system-monitor
        elif command -v mate-system-monitor >/dev/null 2>&1; then
          exec mate-system-monitor
        elif command -v kitty >/dev/null 2>&1; then
          exec kitty -e htop
        elif command -v alacritty >/dev/null 2>&1; then
          exec alacritty -e htop
        else
          exec ${pkgs.xterm}/bin/xterm -e htop
        fi
      '';
      executable = true;
    };

    home.file.".local/bin/waybar-pick-theme" = {
      source = waybarDir + "/scripts/waybar-pick-theme.sh";
      executable = true;
    };
    home.file.".local/bin/waybar-switch-theme" = {
      source = waybarDir + "/scripts/waybar-switch-theme.sh";
      executable = true;
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}: let
  scriptsDir = ./scripts;

  # Patch waypaper.sh to source the shared helper in ~/.config/hypr/scripts/
  patchedWallpaperSh = let
    original = builtins.readFile (scriptsDir + "/waypaper.sh");
  in
    lib.replaceStrings
    ["source \"$HOME/.config/hypr/scripts/helper-functions.sh\""] # idempotent
    
    ["source \"$HOME/.config/hypr/scripts/helper-functions.sh\""]
    original;

  # Install ./scripts/<name> -> ~/.local/bin/<name>
  installScript = name: {
    ".local/bin/${name}" = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };

  default_effect = "off\n";
  default_blur = "50x30\n";
  default_automation_interval = "300\n"; # used only if you opt into the legacy loop script
in {
  options = {
    hyprland.wallpaper.enable =
      lib.mkEnableOption "Enable Hyprland wallpaper tools (Waypaper + helpers)";
  };

  config = lib.mkIf config.hyprland.wallpaper.enable {
    ############################
    # Packages
    ############################
    home.packages = with pkgs; [
      waypaper
      hyprpaper # backend
      imagemagick # provides `magick`
      wallust
      matugen
      rofi-wayland
      libnotify # notify-send
      swaynotificationcenter
      git
      # optional extras
      nwg-dock-hyprland
      (python3.withPackages (ps: [ps.pywalfox]))
    ];

    ############################
    # Scripts to ~/.local/bin
    ############################
    home.file = lib.mkMerge [
      {
        ".local/bin/waypaper.sh".text = patchedWallpaperSh;
        ".local/bin/waypaper.sh".executable = true;
      }

      (installScript "waypaper-restore.sh")
      (installScript "waypaper-effects.sh")
      (installScript "waypaper-cache.sh")
      (installScript "waypaper-automation.sh") # legacy loop (optional)
      (installScript "fetch-wallpapers.sh")

      # Defaults / settings the scripts read (overridable elsewhere)
      {
        ".config/hypr/settings/wallpaper-effect.sh".text = lib.mkDefault default_effect;
        ".config/hypr/settings/blur.sh".text = lib.mkDefault default_blur;
        ".config/hypr/settings/wallpaper-automation.sh".text = lib.mkDefault default_automation_interval;
      }

      # Ensure expected directories exist
      {
        ".config/wallpapers/.keep".text = "";
        ".config/hypr/effects/wallpaper/.keep".text = "";
        ".cache/hyprlock-assets/.keep".text = "";
      }
    ];

    ############################
    # Waypaper restore on session start (recommended)
    ############################
    systemd.user.services."waypaper-restore" = {
      Unit = {
        Description = "Restore last wallpaper via Waypaper";
        After = ["hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.waypaper}/bin/waypaper --backend hyprpaper --restore";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    ############################
    # Random rotation using a systemd timer (clean + robust)
    ############################
    systemd.user.services."waypaper-random" = {
      Unit = {
        Description = "Set a random wallpaper with Waypaper";
        After = ["hyprland-env.service"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.waypaper}/bin/waypaper --backend hyprpaper --folder ${config.xdg.configHome}/wallpapers --random";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    systemd.user.timers."waypaper-random" = {
      Unit = {Description = "Random wallpaper timer";};
      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min"; # change interval as you prefer
        Unit = "waypaper-random.service";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    ############################
    # PATH
    ############################
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

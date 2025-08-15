{
  config,
  pkgs,
  lib,
  ...
}: let
  scriptsDir = ./scripts;

  # Helper om scripts te installeren naar ~/.local/bin
  installScript = name: {
    ".local/bin/${name}" = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };

  default_effect = "off\n";
  default_blur = "50x30\n";
  default_automation_interval = "300\n"; # alleen gebruikt door legacy toggle-script
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
      hyprpaper
      imagemagick
      wallust
      matugen
      rofi-wayland
      libnotify
      swaynotificationcenter
      git
      nwg-dock-hyprland
      (python3.withPackages (ps: [ps.pywalfox]))
    ];

    ############################
    # Scripts naar ~/.local/bin (namen overeenkomend met jouw map)
    ############################
    home.file = lib.mkMerge [
      (installScript "wallpaper.sh")
      (installScript "wallpaper-restore.sh")
      (installScript "wallpaper-effects.sh")
      (installScript "wallpaper-cache.sh")
      (installScript "wallpaper-automation.sh") # legacy toggle (optioneel)
      (installScript "fetch-wallpapers.sh")

      # Defaults / settings die je scripts lezen
      {
        ".config/hypr/settings/wallpaper-effect.sh".text = lib.mkDefault default_effect;
        ".config/hypr/settings/blur.sh".text = lib.mkDefault default_blur;
        ".config/hypr/settings/wallpaper-automation.sh".text = lib.mkDefault default_automation_interval;
      }

      # Verwachte directories
      {
        ".config/wallpapers/.keep".text = "";
        ".config/hypr/effects/wallpaper/.keep".text = "";
        ".cache/hyprlock-assets/.keep".text = "";
      }
    ];

    ############################
    # Waypaper restore bij sessiestart
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
    # Random rotatie via systemd timer
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
        OnUnitActiveSec = "5min"; # pas aan naar smaak
        Unit = "waypaper-random.service";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

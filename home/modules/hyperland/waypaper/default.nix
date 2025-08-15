{
  config,
  pkgs,
  lib,
  ...
}: let
  scriptsDir = ./scripts;

  installScript = name: {
    ".local/bin/${name}" = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };

  default_effect = "off\n";
  default_blur = "50x30\n";
  default_automation_interval = "300\n";
in {
  options = {
    hyprland.wallpaper.enable =
      lib.mkEnableOption "Enable Hyprland wallpaper tools (Waypaper + helpers)";

    hyprland.wallpaper.random.enable = lib.mkEnableOption "Rotate wallpapers randomly via a systemd timer";
    hyprland.wallpaper.random.intervalSeconds = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Interval (seconds) for the random wallpaper timer.";
    };
  };

  config = lib.mkIf config.hyprland.wallpaper.enable {
    ############################
    # Ensure user units start on switch
    ############################
    systemd.user.startServices = "sd-switch";

    ############################
    # Packages
    ############################
    home.packages =
      (with pkgs; [
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
      ])
      ++ lib.optionals (pkgs ? pywalfox) [pkgs.pywalfox];

    ############################
    # Scripts -> ~/.local/bin
    ############################
    home.file = lib.mkMerge [
      (installScript "wallpaper.sh")
      (installScript "wallpaper-restore.sh")
      (installScript "wallpaper-effects.sh")
      (installScript "wallpaper-cache.sh")
      (installScript "wallpaper-automation.sh")
      (installScript "fetch-wallpapers.sh")

      {
        ".config/hypr/settings/wallpaper-effect.sh".text = lib.mkDefault default_effect;
        ".config/hypr/settings/blur.sh".text = lib.mkDefault default_blur;
        ".config/hypr/settings/wallpaper-automation.sh".text = lib.mkDefault default_automation_interval;
      }

      {
        ".config/wallpapers/.keep".text = "";
        ".cache/hyprlock-assets/.keep".text = "";
      }
    ];

    ############################
    # Restore last wallpaper on session start
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
    # Random rotation via systemd timer (conditional)
    ############################
    # Service always defined (lightweight); timer only if enabled.
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

    # Timer only if the option is enabled
    systemd.user.timers."waypaper-random" = lib.mkIf config.hyprland.wallpaper.random.enable {
      Unit = {Description = "Random wallpaper timer";};
      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "${toString config.hyprland.wallpaper.random.intervalSeconds}s";
        Unit = "waypaper-random.service";
      };
      Install = {WantedBy = ["hyprland-session.target"];};
    };

    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

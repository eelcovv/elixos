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
    ["source \"./library.sh\""]
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
  default_automation_interval = "60\n";
in {
  options = {
    hyprland.wallpaper.enable =
      lib.mkEnableOption "Enable Hyprland wallpaper tools (Waypaper + helpers)";
  };

  config = lib.mkIf config.hyprland.wallpaper.enable {
    home.packages = with pkgs; [
      waypaper
      imagemagick # provides `magick`
      wallust
      matugen
      rofi-wayland
      libnotify # notify-send
      swaynotificationcenter
      git
      # optional:
      nwg-dock-hyprland
      (python3.withPackages (ps: [ps.pywalfox]))
    ];

    # Scripts to ~/.local/bin
    home.file = lib.mkMerge [
      {
        ".local/bin/waypaper.sh".text = patchedWallpaperSh;
        ".local/bin/waypaper.sh".executable = true;
      }

      (installScript "waypaper-restore.sh")
      (installScript "waypaper-effects.sh")
      (installScript "waypaper-cache.sh")
      (installScript "waypaper-automation.sh")
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

    # Optional: systemd user service for automation
    systemd.user.services."wallpaper-automation" = {
      Unit = {
        Description = "Hypr wallpaper automation (random via waypaper)";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${config.home.homeDirectory}/.local/bin/waypaper-automation.sh";
        Restart = "on-failure";
      };
      Install = {WantedBy = ["default.target"];};
    };

    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

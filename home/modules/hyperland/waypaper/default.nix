{
  config,
  pkgs,
  lib,
  ...
}: let
  # Directory that contains your wallpaper scripts:
  #   ./scripts/wallpaper.sh
  #   ./scripts/wallpaper-restore.sh
  #   ./scripts/wallpaper-effects.sh
  #   ./scripts/wallpaper-cache.sh
  #   ./scripts/wallpaper-automation.sh
  #   ./scripts/fetch-wallpapers.sh
  scriptsDir = ./scripts;

  # Read and patch wallpaper.sh so it sources the shared helper/library from ~/.config:
  patchedWallpaperSh = let
    original = builtins.readFile (scriptsDir + "/wallpaper.sh");
  in
    lib.replaceStrings
    ["source \"./library.sh\""]
    ["source \"$HOME/.config/hypr/scripts/library.sh\""]
    original;

  # Helper to install a script file from ./scripts to ~/.local/bin/<name>
  installScript = name: {
    ".local/bin/${name}" = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };

  # Safe defaults for settings that the scripts expect. Users can override these later.
  default_effect = "off\n";
  default_blur = "50x30\n";
  default_automation_interval = "60\n";

  # Minimal fallback for library.sh (logger) — use mkDefault so your own file can override it.
  fallback_library_sh = ''
    #!/usr/bin/env bash
    _writeLog() { echo ":: $*"; }
  '';
in {
  options = {
    hyprland.wallpaper.enable = lib.mkEnableOption "Enable Hyprland wallpaper tools (Waypaper + helpers)";
  };

  config = lib.mkIf config.hyprland.wallpaper.enable {
    ################################
    # Packages required by the scripts
    ################################
    home.packages = with pkgs; [
      waypaper
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

    ################################
    # Install scripts to ~/.local/bin (from files on disk)
    ################################
    home.file = lib.mkMerge [
      # Patched wallpaper.sh (text to apply the source-path fix)
      {
        ".local/bin/wallpaper.sh".text = patchedWallpaperSh;
        ".local/bin/wallpaper.sh".executable = true;
      }

      # All other scripts are installed 1:1 from repo
      (installScript "wallpaper-restore.sh")
      (installScript "wallpaper-effects.sh")
      (installScript "wallpaper-cache.sh")
      (installScript "wallpaper-automation.sh")
      (installScript "fetch-wallpapers.sh")

      # Provide a fallback library.sh unless you already ship your own in another module.
      {
        ".config/hypr/scripts/library.sh".text = lib.mkDefault fallback_library_sh;
        ".config/hypr/scripts/library.sh".executable = true;
      }

      # Defaults / settings that the scripts read (can be overridden later)
      {
        ".config/hypr/settings/wallpaper-effect.sh".text = lib.mkDefault default_effect;
        ".config/hypr/settings/blur.sh".text = lib.mkDefault default_blur;
        ".config/hypr/settings/wallpaper-automation.sh".text = lib.mkDefault default_automation_interval;
      }

      # Ensure all directories the scripts expect do exist
      {
        ".config/wallpapers/.keep".text = "";
        ".config/hypr/effects/wallpaper/.keep".text = "";
        ".cache/hyprlock-assets/.keep".text = "";
      }
    ];

    ################################
    # Optional: systemd user service for automation (more robust than self-loop)
    ################################
    systemd.user.services."wallpaper-automation" = {
      Unit = {
        Description = "Hypr wallpaper automation (random via waypaper)";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${config.home.homeDirectory}/.local/bin/wallpaper-automation.sh";
        Restart = "on-failure";
      };
      Install = {WantedBy = ["default.target"];};
    };

    # Not auto-enabled; you can toggle via your script or enable it explicitly:
    # systemd.user.services."wallpaper-automation".Install.WantedBy = [ "default.target" ];

    ################################
    # PATH convenience
    ################################
    home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  };
}

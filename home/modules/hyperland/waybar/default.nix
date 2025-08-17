{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.; # map waar deze default.nix staat
  scriptsDir = ./scripts; # verwacht scripts/ met *.sh
  cfgPath = "${config.xdg.configHome}/waybar";
in {
  ##########################################################################
  # Sanity checks (faal vroeg als themes/ of scripts/ ontbreken)
  ##########################################################################
  assertions = [
    {
      assertion = builtins.pathExists (waybarDir + "/themes");
      message = "waybar/default.nix: expected ./themes next to this module.";
    }
    {
      assertion = builtins.pathExists scriptsDir;
      message = "waybar/default.nix: expected ./scripts next to this module.";
    }
  ];

  ##########################################################################
  # Packages used by the picker (menu + notifications)
  ##########################################################################
  home.packages = with pkgs; [
    rofi-wayland
    swaynotificationcenter
    dunst
  ];

  ##########################################################################
  # Expose repo themes to ~/.config/waybar/themes (bron voor seed/switch)
  ##########################################################################
  xdg.configFile."waybar/themes".source = waybarDir + "/themes";

  # (Optioneel) als je een globale modules.jsonc of colors.css wilt meeleveren,
  # kun je ze hier ook koppelen. Seed/switch gebruikt echter "current/*".
  # xdg.configFile."waybar/modules.jsonc".source = waybarDir + "/modules.jsonc";
  # xdg.configFile."waybar/colors.css".source   = waybarDir + "/colors.css";

  ##########################################################################
  # Install helper-driven switcher scripts into ~/.local/bin
  ##########################################################################
  home.file.".local/bin/waybar-switch-theme" = {
    source = scriptsDir + "/waybar-switch-theme.sh";
    executable = true;
  };
  home.file.".local/bin/waybar-pick-theme" = {
    source = scriptsDir + "/waybar-pick-theme.sh";
    executable = true;
  };
  home.file.".local/bin/waybar-seed" = {
    source = scriptsDir + "/waybar-seed.sh";
    executable = true;
  };

  ##########################################################################
  # Bootstrap: seed alleen als er nog geen resolved style aanwezig is
  # (geeft nu wél themes/ mee, dus seed zal een echte variant kunnen vinden)
  ##########################################################################
  home.activation.bootstrapWaybarIfMissing = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    if [ ! -e "${cfgPath}/current/style.resolved.css" ]; then
      "${config.home.homeDirectory}/.local/bin/waybar-seed"
    fi
  '';

  ##########################################################################
  # Belt & suspenders: forceer de entrypoint-symlinks naar current/*
  ##########################################################################
  home.activation.waybarEntryPoints = lib.hm.dag.entryAfter ["bootstrapWaybarIfMissing"] ''
    set -eu
    CFG="${cfgPath}"
    CUR="$CFG/current"
    mkdir -p "$CFG" "$CUR"
    ln -sfn "$CUR/config.jsonc"       "$CFG/config"
    ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
    ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
    ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
    ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"
  '';

  ##########################################################################
  # Waybar it self (without systemd-user unit to prevent double starts
  ##########################################################################
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false;

  # Zorg dat ~/.local/bin in PATH staat voor de scripts
  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
}

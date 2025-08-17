{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  scriptsDir = ./scripts;
  cfgPath = "${config.xdg.configHome}/waybar";
in {
  ##########################################################################
  # Packages used by the picker (menu + notifications)
  ##########################################################################
  home.packages = with pkgs; [
    rofi-wayland
    swaynotificationcenter
    dunst
  ];

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

  home.activation.bootstrapWaybarIfMissing = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    if [ ! -e "${cfgPath}/current/style.resolved.css" ]; then
      "${config.home.homeDirectory}/.local/bin/waybar-seed"
    fi
  '';

  # Keep forcing entry points to current/* (belt & suspenders)
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

  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false;

  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
}

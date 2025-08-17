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
  # ... (jouw packages, switchers, themes, optional colors/modules blijven hetzelfde) ...

  # Install the seed script into ~/.local/bin
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

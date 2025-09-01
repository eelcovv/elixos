{
  config,
  pkgs,
  lib,
  ...
}: let
  cfgPath = "${config.xdg.configHome}/waybar";
  waitForHypr = pkgs.writeShellScript "wait-for-hypr" ''
    # wacht max 5s tot hyprctl werkt (Hyprland actief)
    for i in $(seq 1 50); do
      if ${pkgs.hyprland}/bin/hyprctl -j monitors >/dev/null 2>&1; then
        exit 0
      fi
      sleep 0.1
    done
    exit 0
  '';
in {
  programs.waybar.enable = true;
  programs.waybar.package = pkgs.waybar;
  programs.waybar.systemd.enable = false; # we gebruiken onze eigen unit

  systemd.user.services.waybar-managed = {
    Unit = {
      Description = "Waybar (HM managed)";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
      # Start alleen in een Wayland sessie; Hypr maakt %t/hypr/ aan
      ConditionPathExistsGlob = "%t/hypr/*";
      # (optioneel) voorkom dubbele starts naast standaard waybar.service:
      Conflicts = ["waybar.service"];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${waitForHypr}";
      ExecStart = "${pkgs.waybar}/bin/waybar -l info -c ${cfgPath}/config.jsonc -s ${cfgPath}/style.css";
      ExecReload = "${pkgs.coreutils}/bin/kill -USR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = "500ms";
      Environment = [
        "WAYBAR_CONFIG=%h/.config/waybar/config.jsonc"
        "WAYBAR_STYLE=%h/.config/waybar/style.css"
      ];
    };
    Install = {WantedBy = ["graphical-session.target"];};
  };

  # Seed je configbestanden als ze niet bestaan
  home.activation.ensureWaybarSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
    mkdir -p "$cfg_dir"

    [ -f "$cfg_dir/config.jsonc" ] || install -Dm0644 "${./themes/default/config.jsonc}" "$cfg_dir/config.jsonc"
    [ -f "$cfg_dir/style.css"    ] || install -Dm0644 "${./themes/default/style.css}"    "$cfg_dir/style.css"
    [ -f "$cfg_dir/colors.css"   ] || { printf '/* default colors */\n' >"$cfg_dir/colors.css"; chmod 0644 "$cfg_dir/colors.css"; }
    [ -f "$cfg_dir/modules.jsonc"] || { printf '{}\n'  >"$cfg_dir/modules.jsonc"; chmod 0644 "$cfg_dir/modules.jsonc"; }
    [ -f "$cfg_dir/waybar-quicklinks.json"] || { printf '[]\n' >"$cfg_dir/waybar-quicklinks.json"; chmod 0644 "$cfg_dir/waybar-quicklinks.json"; }
    ln -sfn "$cfg_dir/config.jsonc" "$cfg_dir/config"  # compat
  '';

  # Zorg dat ~/.local/bin op PATH staat (voor je tools)
  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
}

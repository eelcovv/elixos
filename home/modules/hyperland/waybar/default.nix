{
  config,
  pkgs,
  lib,
  ...
}: let
  # Korte wachtroutine zodat Hyprland IPC en outputs ‘up’ zijn
  waitForHypr = pkgs.writeShellScript "wait-for-hypr" ''
    # Wacht max ~5s
    for i in $(seq 1 50); do
      if ${pkgs.hyprland}/bin/hyprctl -j monitors >/dev/null 2>&1; then
        exit 0
      fi
      sleep 0.1
    done
    exit 0
  '';

  # Optioneel: helper om Waybar netjes te herladen vanuit scripts
  waybarReload = pkgs.writeShellScriptBin "waybar-reload" ''
    # Probeer nette reload (SIGUSR2); val terug op restart
    systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service
  '';
in {
  home.packages = [
    pkgs.waybar
    waybarReload
  ];

  # Belangrijk: zorg dat Hyprland Waybar niet óók start (haal exec-once = waybar uit je Hypr config)
  # We beheren één eigen service met een andere naam dan de vendor unit: waybar-managed.service
  systemd.user.services."waybar-managed" = {
    Unit = {
      Description = "Waybar (managed by Home Manager)";
      # Hang aan de standaard user target i.p.v. graphical-session.target
      After = ["default.target"];
      PartOf = ["default.target"];
    };
    Service = {
      Type = "simple";
      # Wacht even op Hyprland zodat Waybar consistent start
      ExecStartPre = "${waitForHypr}";
      ExecStart = "${pkgs.waybar}/bin/waybar";
      ExecReload = "kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = 0.5;
      # (optioneel) maak logging stiller:
      # Environment = "WAYBAR_LOG_LEVEL=warning";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  # Handig als je theme-switcher een reload wil doen:
  home.sessionPath = ["${waybarReload}/bin"];
}

systemd.user.services."waybar-managed" = {
  Unit = { /* …zoals je had… */ };
  Service = {
    Type = "simple";
    Environment = [ "XDG_RUNTIME_DIR=%t" ];
    ExecStartPre = [ "${waitForHypr}" "${pkgs.coreutils}/bin/sleep 0.25" ];
    ExecStart = "${pkgs.waybar}/bin/waybar -l trace -c ${cfgPath}/config -s ${cfgPath}/style.css";

    # ↓ deze drie regels helpen tegen vastlopers bij stop/restart
    TimeoutStopSec = "2s";
    KillMode = "mixed";
    ExecStopPost = "${pkgs.procps}/bin/pkill -9 -f '(^|/)waybar($| )' || true";

    Restart = "on-failure";
    RestartSec = "1s";
    StandardOutput = "journal";
    StandardError  = "journal";
  };
  Install.WantedBy = [ "hyprland-session.target" ];
};

systemd.user.services."nm-applet" = {
  Unit = { /* …zoals je had… */ };
  Service = {
    ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";

    # idem dito, kort stoppen en daarna hard killen indien nodig
    TimeoutStopSec = "2s";
    KillMode = "mixed";
    ExecStopPost = "${pkgs.procps}/bin/pkill -9 -f '(^|/)nm-applet($| )' || true";

    Restart = "on-failure";
    RestartSec = 1;
    Environment = [ "XDG_RUNTIME_DIR=%t" ];
  };
  Install.WantedBy = [ "hyprland-session.target" ];
};


  # One-shot user service to fetch wallpapers (invoked on demand or by timer)
  systemd.user.services."waypaper-fetch" = {
    Unit = {
      Description = "Fetch wallpapers (central, repo script)";
      # In user scope, network-online.target is unreliable; keep it simple.
      After = [ "hyprland-env.service" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "oneshot";

      # Run via bash and never fail the unit (prevents 'degraded' on flaky net).
      # We still LOG everything to the journal for debugging.
      ExecStart = ''
        ${pkgs.bash}/bin/bash -lc '${lib.getExe fetcherBin}'; exit 0
      '';

      # Helpful logging to the journal:
      StandardOutput = "journal";
      StandardError  = "journal";

      # Environment the script expects
      Environment = [
        "XDG_CONFIG_HOME=%h/.config"
        "HOME=%h"
        "WALLPAPER_DIR=${wpDir}"
        "GIT_TERMINAL_PROMPT=0"
        "GIT_ASKPASS=true"
      ];

      TimeoutStartSec   = "3min";
      Nice              = 19;
      IOSchedulingClass = "idle";
    };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
  };


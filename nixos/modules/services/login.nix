{
  config,
  lib,
  pkgs,
  ...
}: {
  # Configure systemd-logind [Login] section
  services.logind.settings.Login = {
    # Always ignore lid switch (for debugging)
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";

    # Optional: ensure no idle-triggered suspend interferes
    IdleAction = "ignore";
  };
}

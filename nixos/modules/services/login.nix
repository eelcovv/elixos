{
  config,
  lib,
  pkgs,
  ...
}: {
  services.logind = {
    # Usually already enabled, but explicitly won't hurt
    enable = true;

    # Behavior without dock (free to choose)
    lidSwitch = "suspend";

    # Important: if there is an external monitor → don't sleep when clapping
    lidSwitchDocked = "ignore";

    # Optional: Don't sleep even with mains power / external power
    extraConfig = ''
      HandleLidSwitchExternalPower=ignore
    '';
  };
}

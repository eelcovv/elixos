# home/modules/engineering/paraview-flatpak.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.engineering.paraviewFlatpak;
  flatpakBin = "${pkgs.flatpak}/bin/flatpak";
  flathubRepo = "https://flathub.org/repo/flathub.flatpakrepo";
in {
  options.engineering.paraviewFlatpak = {
    enable = lib.mkEnableOption "Install ParaView via Flatpak for this user";

    appId = lib.mkOption {
      type = lib.types.str;
      default = "org.paraview.ParaView";
      description = "Flatpak application ID for ParaView.";
    };

    addFlathub = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add Flathub remote for this user if missing.";
    };

    autoUpdate = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable a user timer to periodically run 'flatpak update --user'.";
      };
      onCalendar = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "systemd OnCalendar for the user-level flatpak update timer.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure the flatpak CLI is available for the user
    home.packages = [pkgs.flatpak];

    # Add Flathub remote (user scope) if it doesn't exist yet
    home.activation.flatpakUserFlathub = lib.mkIf cfg.addFlathub (lib.hm.dag.entryAfter ["writeBoundary"] ''
      if ! ${flatpakBin} remotes --user --columns=name | grep -qx "flathub"; then
        ${flatpakBin} remote-add --if-not-exists --user flathub ${flathubRepo} || true
      fi
    '');

    # Install ParaView (user scope) if missing
    home.activation.flatpakInstallParaView = lib.hm.dag.entryAfter ["flatpakUserFlathub"] ''
      if ! ${flatpakBin} list --app --user --columns=application | grep -qx "${cfg.appId}"; then
        ${flatpakBin} install -y --user flathub ${cfg.appId} || true
      fi
    '';

    # Optional: user-level auto-update via systemd timer
    systemd.user.services."flatpak-update-user" = lib.mkIf cfg.autoUpdate.enable {
      Unit = {
        Description = "Flatpak update (user scope)";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${flatpakBin} update -y --user";
      };
      Install.WantedBy = ["default.target"];
    };

    systemd.user.timers."flatpak-update-user" = lib.mkIf cfg.autoUpdate.enable {
      Unit.Description = "Schedule Flatpak update (user scope)";
      Timer = {
        OnCalendar = cfg.autoUpdate.onCalendar;
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };

    # Convenience launcher to run the Flatpak explicitly
    home.file.".local/bin/paraview-flatpak" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec ${flatpakBin} run ${cfg.appId} "$@"
      '';
    };
  };
}

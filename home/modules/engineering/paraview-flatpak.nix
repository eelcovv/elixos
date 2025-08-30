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

    wrapBinary = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install ~/.local/bin/paraview that runs the Flatpak ParaView.";
    };

    desktopEntries = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Create desktop entries for ParaView Flatpak.";
      };
      x11Variant = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Also create a desktop entry that forces the X11 (xcb) backend.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.flatpak];

    home.sessionPath = lib.mkBefore ["${config.home.homeDirectory}/.local/bin"];

    # Make Flatpak-exported .desktop files visible in menus
    home.sessionVariables.XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS";

    home.activation.flatpakUserFlathub = lib.mkIf cfg.addFlathub (lib.hm.dag.entryAfter ["writeBoundary"] ''
      if ! ${flatpakBin} remotes --user --columns=name | grep -qx "flathub"; then
        ${flatpakBin} remote-add --if-not-exists --user flathub ${flathubRepo} || true
      fi
    '');

    home.activation.flatpakInstallParaView = lib.hm.dag.entryAfter ["flatpakUserFlathub"] ''
      if ! ${flatpakBin} list --app --user --columns=application | grep -qx "${cfg.appId}"; then
        ${flatpakBin} install -y --user flathub ${cfg.appId} || true
      fi
    '';

    systemd.user.services."flatpak-update-user" = lib.mkIf cfg.autoUpdate.enable {
      Unit = {Description = "Flatpak update (user scope)";};
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

    home.file.".local/bin/paraview-flatpak" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec ${flatpakBin} run ${cfg.appId} "$@"
      '';
    };

    home.file.".local/bin/paraview" = lib.mkIf cfg.wrapBinary {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec ${flatpakBin} run ${cfg.appId} "$@"
      '';
    };

    xdg.desktopEntries.paraview-flatpak = lib.mkIf cfg.desktopEntries.enable {
      name = "ParaView (Flatpak)";
      genericName = "Data analysis and visualization";
      comment = "ParaView via Flatpak";
      exec = "flatpak run ${cfg.appId} %U";
      icon = cfg.appId;
      terminal = false;
      categories = ["Graphics" "Science" "Education"];
      mimeType = ["application/x-paraview"];
      startupNotify = true;
    };

    xdg.desktopEntries.paraview-flatpak-x11 = lib.mkIf (cfg.desktopEntries.enable && cfg.desktopEntries.x11Variant) {
      name = "ParaView (Flatpak, X11)";
      genericName = "Data analysis and visualization";
      comment = "ParaView via Flatpak (forces X11 backend)";
      exec = "env QT_QPA_PLATFORM=xcb flatpak run ${cfg.appId} %U";
      icon = cfg.appId;
      terminal = false;
      categories = ["Graphics" "Science" "Education"];
      startupNotify = true;
    };
  };
}

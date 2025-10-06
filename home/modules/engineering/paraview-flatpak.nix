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

  # Common flatpak run flags. We inject env vars that fix the misplaced file dialog:
  # - PARAVIEW_USE_NATIVE_FILE_DIALOG=1 → use Qt's native dialog (works reliably)
  commonRun = "run --env=PARAVIEW_USE_NATIVE_FILE_DIALOG=1 ${cfg.appId}";

  # X11 variant: additionally force Qt to use XCB (XWayland), which avoids Wayland geometry bugs.
  x11Run = "run --env=PARAVIEW_USE_NATIVE_FILE_DIALOG=1 --env=QT_QPA_PLATFORM=xcb ${cfg.appId}";
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

    # CLI wrappers
    home.file.".local/bin/paraview-flatpak" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec ${flatpakBin} ${commonRun} "$@"
      '';
    };

    home.file.".local/bin/paraview" = lib.mkIf cfg.wrapBinary {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Wrapper that fixes the off-screen file dialog on Hyprland/Wayland by
        # enabling ParaView's native file dialog. If you want to force X11,
        # set PARAVIEW_FORCE_X11=1 in your env or use the X11 desktop entry.
        set -euo pipefail
        if [[ "${PARAVIEW_FORCE_X11: -0}" = "1" ]]; then
          exec ${flatpakBin} ${x11Run} "$@"
        else
          exec ${flatpakBin} ${commonRun} "$@"
        fi
      '';
    };

    # Desktop entries
    xdg.desktopEntries.paraview-flatpak = lib.mkIf cfg.desktopEntries.enable {
      name = "ParaView (Flatpak)";
      genericName = "Data analysis and visualization";
      comment = "ParaView via Flatpak (native file dialog enabled)";
      exec = "flatpak ${commonRun} %U";
      icon = cfg.appId;
      terminal = false;
      categories = ["Graphics" "Science" "Education"];
      mimeType = ["application/x-paraview"];
      startupNotify = true;
    };

    xdg.desktopEntries.paraview-flatpak-x11 = lib.mkIf (cfg.desktopEntries.enable && cfg.desktopEntries.x11Variant) {
      name = "ParaView (Flatpak, X11)";
      genericName = "Data analysis and visualization";
      comment = "ParaView via Flatpak (forces X11 backend; fixes Wayland dialog placement)";
      exec = "flatpak ${x11Run} %U";
      icon = cfg.appId;
      terminal = false;
      categories = ["Graphics" "Science" "Education"];
      startupNotify = true;
    };
  };
}

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

  # Common flatpak run command:
  # - PARAVIEW_USE_NATIVE_FILE_DIALOG=1 → forceer Qt-native dialoog als sandbox het toelaat
  commonRun = "run --env=PARAVIEW_USE_NATIVE_FILE_DIALOG=1 ${cfg.appId}";

  # X11-variant (XWayland): robuuste fallback tegen Wayland-geometry issues
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
      description = "Install ~/.local/bin/paraview-flatpak helper script.";
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

    # Nieuwe opties: zet Flatpak override + Hyprland rules
    flatpakOverrideNativeDialog = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Apply "flatpak override --filesystem=home" so the Qt native file dialog
        can access the FS without portals. This prevents off-screen portal dialogs.
      '';
    };

    hyprlandRules = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Hyprland window rules to center/float file dialogs.";
      };
      # Je kunt extra titels/classes toevoegen indien gewenst.
      titles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["Open File" "Open Folder" "Save As" "Save File"];
        description = "Dialog window titles to match (regex anchors added automatically).";
      };
      classes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "xdg-desktop-portal-gtk"
          "xdg-desktop-portal-kde"
          "org.kde.kdialog"
        ];
        description = "WM classes of common portal dialogs to match.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.flatpak];
    home.sessionPath = lib.mkBefore ["${config.home.homeDirectory}/.local/bin"];

    # Zorg dat Flatpak-exported .desktop files in je menu zichtbaar zijn
    home.sessionVariables.XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS";

    # 1) Flathub toevoegen (indien nodig)
    home.activation.flatpakUserFlathub = lib.mkIf cfg.addFlathub (lib.hm.dag.entryAfter ["writeBoundary"] ''
      if ! ${flatpakBin} remotes --user --columns=name | grep -qx "flathub"; then
        ${flatpakBin} remote-add --if-not-exists --user flathub ${flathubRepo} || true
      fi
    '');

    # 2) ParaView installeren (indien nodig)
    home.activation.flatpakInstallParaView = lib.hm.dag.entryAfter ["flatpakUserFlathub"] ''
      if ! ${flatpakBin} list --app --user --columns=application | grep -qx "${cfg.appId}"; then
        ${flatpakBin} install -y --user flathub ${cfg.appId} || true
      fi
    '';

    # 3) Override zodat Qt-native file dialog niet terugvalt op portal vanwege FS sandbox
    home.activation.flatpakOverrideParaView = lib.mkIf cfg.flatpakOverrideNativeDialog (
      lib.hm.dag.entryAfter ["flatpakInstallParaView"] ''
        # Grant access to $HOME so native dialog can browse files without the portal
        ${flatpakBin} override --user --filesystem=home ${cfg.appId} || true
      ''
    );

    # Auto-update
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

    # CLI helper
    home.file.".local/bin/paraview-flatpak" = lib.mkIf cfg.wrapBinary {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec ${flatpakBin} ${commonRun} "$@"
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

    # 4) Hyprland rules om eventuele portal-dialogen te centreren/floaten als ze tóch gebruikt worden
    wayland.windowManager.hyprland.settings = lib.mkIf cfg.hyprlandRules.enable {
      # Combineer regels voor titles en classes:
      windowrulev2 = let
        # regex met anchors voor titels
        titleRules =
          map (t: "float,title:^(?i:" + lib.escapeRegex t + ")$") cfg.hyprlandRules.titles
          ++ map (t: "center,title:^(?i:" + lib.escapeRegex t + ")$") cfg.hyprlandRules.titles
          ++ map (t: "move 50% 50%,title:^(?i:" + lib.escapeRegex t + ")$") cfg.hyprlandRules.titles
          ++ map (t: "size 70% 70%,title:^(?i:" + lib.escapeRegex t + ")$") cfg.hyprlandRules.titles;

        classRules =
          map (c: "float,class:^(" + lib.escapeRegex c + ")$") cfg.hyprlandRules.classes
          ++ map (c: "center,class:^(" + lib.escapeRegex c + ")$") cfg.hyprlandRules.classes
          ++ map (c: "move 50% 50%,class:^(" + lib.escapeRegex c + ")$") cfg.hyprlandRules.classes
          ++ map (c: "size 70% 70%,class:^(" + lib.escapeRegex c + ")$") cfg.hyprlandRules.classes;
      in
        titleRules ++ classRules;
    };
  };
}

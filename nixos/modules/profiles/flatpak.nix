{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.profiles.flatpak;
  flatpakBin = "${pkgs.flatpak}/bin/flatpak";
  flathubRepo = "https://flathub.org/repo/flathub.flatpakrepo";
in {
  options.profiles.flatpak = {
    enable = lib.mkEnableOption "Flatpak runtime and portals";

    addSystemFlathub = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Add the Flathub remote at the system scope ( --system ) if it's missing.
        This makes the remote available for all users without per-user setup.
      '';
    };

    systemApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["org.paraview.ParaView" "org.gimp.GIMP"];
      description = ''
        Flatpak application IDs to install at the system scope ( --system ) from Flathub.
        Apps will be installed if missing; updates are not managed automatically here.
      '';
    };

    portals.hyprland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable xdg-desktop-portal-hyprland.";
    };

    portals.gtk = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable xdg-desktop-portal-gtk as a generic fallback.";
    };
  };

  config = lib.mkIf cfg.enable {
    # 1) Flatpak daemon
    services.flatpak.enable = true;

    # 2) XDG Portals for Wayland/Hyprland
    xdg.portal.enable = true;
    xdg.portal.extraPortals =
      (lib.optionals cfg.portals.gtk [pkgs.xdg-desktop-portal-gtk])
      ++ (lib.optionals cfg.portals.hyprland [pkgs.xdg-desktop-portal-hyprland]);

    # 3) Provide the flatpak CLI system-wide
    environment.systemPackages = [pkgs.flatpak];

    # 4) System-wide Flathub remote (one-time add at activation)
    system.activationScripts.flatpak-flathub = lib.mkIf cfg.addSystemFlathub {
      deps = [];
      text = ''
        # Add Flathub as a system remote if it's not present
        if ! ${flatpakBin} remotes --system --columns=name | grep -qx "flathub"; then
          ${flatpakBin} remote-add --if-not-exists --system flathub ${flathubRepo} || true
        fi
      '';
    };

    # 5) System-wide app installation (idempotent)
    system.activationScripts.flatpak-system-apps = lib.mkIf (cfg.systemApps != []) {
      deps = ["flatpak-flathub"];
      text = ''
        # Install requested system-scope apps if they are missing
        for app in ${lib.escapeShellArg (lib.concatStringsSep " " cfg.systemApps)}; do
          if ! ${flatpakBin} list --app --system --columns=application | grep -qx "$app"; then
            ${flatpakBin} install -y --system flathub "$app" || true
          fi
        done
      '';
    };

    # (Optional) Some apps rely on dconf; harmless to enable.
    programs.dconf.enable = true;
  };
}

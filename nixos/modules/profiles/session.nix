{
  lib,
  pkgs,
  config,
  ...
}: let
  t = lib.types;
in {
  options.profiles.session.seedRememberLast = {
    enable = lib.mkEnableOption "Seed AccountsService so GDM kan 'remember last' starten";
    # username -> sessie-id, bv. "hyprland" | "gnome" | "gnome-xorg" | "plasma"
    mapping = lib.mkOption {
      type = t.attrsOf t.str;
      default = {};
      example = {
        eelco = "hyprland";
        por = "gnome";
      };
      description = "For each user the initial session to seed (only if a traffic jam does not yet exist).";
    };
  };

  config = lib.mkIf config.profiles.session.seedRememberLast.enable {
    # Optioneel: waarschuwing als GDM niet aan staat
    assertions = [
      {
        assertion = config.services.displayManager.gdm.enable or false;
        message = "profile.session.seedremembertlast expects GDM as a display manager.";
      }
    ];

    # Write 1x a Seed file per user if it does not yet exist (TMPFiles 'C' = Create IF Absent)
    systemd.tmpfiles.rules = let
      mkRule = user: sess: let
        sessionType =
          if sess == "gnome-xorg" || sess == "plasma"
          then "x11"
          else "wayland";
        contents = pkgs.writeText "accounts-${user}" ''
          [User]
          XSession=${sess}
          Session=${sess}
          SessionType=${sessionType}
          SystemAccount=false
        '';
      in "C /var/lib/AccountsService/users/${user} 0644 root root - ${contents}";
    in
      lib.mapAttrsToList mkRule config.profiles.session.seedRememberLast.mapping;
  };
}

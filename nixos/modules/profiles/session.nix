{
  lib,
  pkgs,
  config,
  ...
}: let
  t = lib.types;
in {
  options.profiles.session.seedRememberLast = {
    enable = lib.mkEnableOption "Seed per-user sessie via AccountsService";
    mapping = lib.mkOption {
      type = t.attrsOf t.str;
      default = {};
      example = {
        eelco = "hyprland";
        por = "plasma";
      };
    };
  };

  config = lib.mkIf config.profiles.session.seedRememberLast.enable {
    systemd.tmpfiles.rules =
      lib.mapAttrsToList
      (
        user: sess: let
          st =
            if sess == "plasmax11" || sess == "gnome-xorg"
            then "x11"
            else "wayland";
          txt = pkgs.writeText "accounts-${user}" ''
            [User]
            XSession=${sess}
            Session=${sess}
            SessionType=${st}
            SystemAccount=false
          '';
        in "C /var/lib/AccountsService/users/${user} 0644 root root - ${txt}"
      )
      config.profiles.session.seedRememberLast.mapping;
  };
}

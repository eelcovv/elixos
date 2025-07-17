{
  config,
  lib,
  pkgs,
  ...
}: {
  services.gnome.gnome-keyring.enable = true;

  systemd.user.services.gnome-keyring-daemon = {
    enable = true;
    description = "GNOME Keyring Daemon for secrets and SSH";
    wantedBy = ["default.target"];
    serviceConfig = {
      ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets,ssh";
      Environment = "SSH_AUTH_SOCK=%t/keyring/ssh";
    };
  };
}

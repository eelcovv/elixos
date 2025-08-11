{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [wireguard-tools];

  # Surfshark private key via sops
  sops.secrets."surfshark/wg/privatekey" = {
    sopsFile = ../../secrets/surfshark/wg/privatekey;
    format = "binary";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # NL (Amsterdam)
  networking.wg-quick.interfaces."wg-surfshark-nl" = {
    address = ["10.14.0.2/16"];
    dns = ["162.252.172.57" "149.154.159.92"];
    privateKeyFile = config.sops.secrets."surfshark/wg/privatekey".path;
    peers = [
      {
        publicKey = "Lxg3jAOKcBA9tGBtB6vEWMFl5LUEB6AwOpuniYn1cig=";
        endpoint = "nl-ams.prod.surfshark.com:51820";
        allowedIPs = ["0.0.0.0/0" "::/0"];
        persistentKeepalive = 25;
      }
    ];
    mtu = 1420;
    autostart = false;
  };

  # Bangkok (Surfshark)
  networking.wg-quick.interfaces."wg-surfshark-bkk" = {
    address = ["10.14.0.2/16"];
    dns = ["162.252.172.57" "149.154.159.92"];
    privateKeyFile = config.sops.secrets."surfshark/wg/privatekey".path;

    peers = [
      {
        publicKey = "OoFY46j/w4uQFyFu/OQ/h3x+ymJ1DJ4UR1fwGNxOxk0=";
        endpoint = "th-bkk.prod.surfshark.com:51820";
        allowedIPs = ["0.0.0.0/0" "::/0"];
        persistentKeepalive = 25;
      }
    ];

    mtu = 1420;
    autostart = false;
  };

  # Singapore (Surfshark)
  networking.wg-quick.interfaces."wg-surfshark-sg" = {
    address = ["10.14.0.2/16"];
    dns = ["162.252.172.57" "149.154.159.92"];
    privateKeyFile = config.sops.secrets."surfshark/wg/privatekey".path;

    peers = [
      {
        publicKey = "MGfgkhJsMVMTO33h1wr76+z6gQr/93VcGdClfbaPsnU=";
        endpoint = "sg-sng.prod.surfshark.com:51820";
        allowedIPs = ["0.0.0.0/0" "::/0"];
        persistentKeepalive = 25;
      }
    ];

    mtu = 1420;
    autostart = false;
  };

  networking.firewall.checkReversePath = "loose";
}

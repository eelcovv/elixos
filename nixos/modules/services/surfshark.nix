{
  config,
  lib,
  pkgs,
  ...
}: {
  # Secret for Surfshark WireGuard VPN
  sops.secrets."surfshark/wg/privatekey" = {
    sopsFile = ./secrets/surfshark.yaml; # pas aan naar jouw bestand
    format = "yaml";
    # Zorg dat alleen root hem kan lezen:
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # WireGuard interface
  networking.wireguard.interfaces.wg-surfshark = {
    # Het /32 (of /128) adres dat Surfshark je geeft
    ips = ["10.x.y.z/32"];

    privateKeyFile = config.sops.secrets."surfshark/wg/privatekey".path;

    # Full tunnel:
    peers = [
      {
        publicKey = "SERVER_PUBLIC_KEY_HIER";
        endpoint = "ams-wg.surfshark.com:51820"; # kies jouw locatie
        allowedIPs = ["0.0.0.0/0" "::/0"];
        persistentKeepalive = 25;
      }
    ];

    # Optional: use Surfshark DNS in stead of your own
    dns = ["SURFSHARK_DNS_IP"];
    # mtu = 1420; # Sometime required in case of performance issues
  };

  # Addons (optional but handy):
  # Less strict reverse path filtering
  networking.firewall.checkReversePath = "loose";
}

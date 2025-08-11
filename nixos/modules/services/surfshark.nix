{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [wireguard-tools];

  sops.secrets."surfshark/wg/privatekey" = {
    sopsFile = ../../secrets/surfshark/wg/privatekey;
    format = "binary";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  networking.wireguard.interfaces.wg-surfshark = {
    ips = ["10.14.0.2/16"];
    privateKeyFile = config.sops.secrets."surfshark/wg/privatekey".path;

    peers = [
      {
        publicKey = "Lxg3jAOKcBA9tGBtB6vEWMFl5LUEB6AwOpuniYn1cig=";
        endpoint = "nl-ams.prod.surfshark.com:51820";
        allowedIPs = ["0.0.0.0/0" "::/0"];
        persistentKeepalive = 25;
      }
    ];

    # vaak nodig, scheelt fragmentatie
    mtu = 1420;

    # Maak een route-exceptie voor het endpoint-IP via je normale default route
    postSetup = ''
      EP=$(getent ahostsv4 nl-ams.prod.surfshark.com | awk "/STREAM/ {print \$1; exit}")
      GW=$(ip route show default | awk "/default/ {print \$3; exit}")
      DEV=$(ip route show default | awk "/default/ {print \$5; exit}")
      [ -n "$EP" ] && [ -n "$GW" ] && [ -n "$DEV" ] && ip route add "$EP" via "$GW" dev "$DEV" || true
    '';
    preShutdown = ''
      EP=$(getent ahostsv4 nl-ams.prod.surfshark.com | awk "/STREAM/ {print \$1; exit}")
      [ -n "$EP" ] && ip route del "$EP" 2>/dev/null || true
    '';
  };

  networking.firewall.checkReversePath = "loose";

  # DNS via resolved + NetworkManager, maar stel de servers hier in:
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.nameservers = ["162.252.172.57" "149.154.159.92" "1.1.1.1" "9.9.9.9"];
}

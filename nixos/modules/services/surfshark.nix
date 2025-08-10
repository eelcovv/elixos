{
  config,
  lib,
  pkgs,
  ...
}: {
  # Make sure the Surfshark WireGuard tools are available
  environment.systemPackages = with pkgs; [wireguard-tools];

  # Private key as sops-secret
  sops.secrets."surfshark/wg/privatekey" = {
    sopsFile = ../../secrets/surfshark.yaml; # vanuit modules/services/ naar secrets/
    format = "yaml";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # WireGuard interface voor Surfshark AMS
  networking.wireguard.interfaces.wg-surfshark = {
    # uit jouw conf:
    ips = ["10.14.0.2/16"];
    privateKeyFile = config.sops.secrets."surfshark/wg/privatekey".path;

    # twee DNS-servers uit je conf
    dns = ["162.252.172.57" "149.154.159.92"];

    peers = [
      {
        # server public key uit je conf
        publicKey = "Lxg3jAOKcBA9tGBtB6vEWMFl5LUEB6AwOpuniYn1cig=";
        endpoint = "nl-ams.prod.surfshark.com:51820";
        allowedIPs = ["0.0.0.0/0"];
        persistentKeepalive = 25;
      }
    ];
  };

  # Handig bij full-tunnel (voorkomt te strenge RP-filter)
  networking.firewall.checkReversePath = "loose";
}

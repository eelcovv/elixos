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

  # wg-quick interface (neemt DNS over uit je conf)
  networking.wg-quick.interfaces."wg-surfshark" = {
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

    mtu = 1420; # helpt soms tegen vertraging
    autostart = false; # alleen starten als jij het zegt
  };

  networking.firewall.checkReversePath = "loose";
}

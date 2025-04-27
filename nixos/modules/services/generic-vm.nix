{

  services = {

    xserver = {
      enable = true;
      videoDrivers = [ "virtio" ];
    };

    # turn on openssh!
    openssh = {
      enable = true;

      # Alleen inloggen met public key, geen wachtwoord
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };

      # Open de poort in de firewall (voor als je die ooit inschakelt)
      openFirewall = true;
    };
  };
}

{

  services = {

    # turn of services we dont use in the vm
    dbus.enable = false;
    bluetooth.enable = false;

    xserver = {
      enable = true;
      videoDrivers = [ "virtio" ];
    };
    services.geoclue.enable = false;


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

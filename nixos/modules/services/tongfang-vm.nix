{
  services.xserver = {
    enable = true;
    videoDrivers = [ "virtio" ]; 
  };

  services.openssh = {
    enable = true;

    # Alleen inloggen met public key, geen wachtwoord
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };

    # Open de poort in de firewall (voor als je die ooit inschakelt)
    openFirewall = true;
  };

  # Zorg ervoor dat je user een SSH key heeft
  users.users.eelco.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@nixos"
  ];
}
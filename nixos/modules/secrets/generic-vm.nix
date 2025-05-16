{
  sops.defaultSopsFile = ../../secrets/generic-vm-ecrets.yaml;
  sops.age.keyFile = "/etc/sops/age/keys.txt";  

  sops.secrets.age_key = {
    path = "/etc/sops/age/keys.txt";
    mode = "0400";
  };

  sops.secrets.id_ed25519 = {
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
  };
}



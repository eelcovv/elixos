{
  sops.defaultSopsFile = ../../secrets/generic-vm-secrets.yaml;

  sops.secrets.id_ed25519 = {
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
  };
}

{
  # this line makes sure that the file which is available in live installer in the 
  # location /root/.config/sops/age/keys.txt is also available in the target system 
  # under /etc/sops/age/keys.txt
  environment.etc."sops/age/keys.txt".source = /root/.config/sops/age/keys.txt;

  sops.defaultSopsFile = ../../secrets/generic-vm-secrets.yaml;
  sops.age.keyFile = "/etc/sops/age/keys.txt";  # <-- hier pas je 'm aan

  sops.secrets.id_ed25519 = {
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
  };
}


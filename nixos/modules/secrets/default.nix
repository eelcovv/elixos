{
  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"
  ];

  sops.age.keyFile = "/etc/sops/age/keys.txt";

  sops.secrets.age_key_root = {
    sopsFile = ../../secrets/age_key_root.yaml;
    path = "/etc/sops/age/keys.txt";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  systemd.services."sops-install-secrets".environment.SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";
}

{
  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"
  ];

  sops.age.keyFile = "/etc/sops/age/keys.txt";

  systemd.services."sops-install-secrets".environment.SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";
}
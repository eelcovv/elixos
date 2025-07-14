{
  # this file should be loaded by all profile to announce that we have the keys.txt file in the
  # /etc/sops/age map
  # this file should be copied there manually, or by running just post-boot-setup, which takes care
  # of copying your keys.txt file
  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"
  ];

  sops.age.keyFile = "/etc/sops/age/keys.txt";

  systemd.services."sops-install-secrets".environment.SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";
}

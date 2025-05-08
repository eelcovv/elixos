{ config, pkgs, ... }:

{
  age.secrets.ssh_key_tongfang_eelco = {
    file = ../../secrets/ssh_key_tongfang_key_eelco.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
  age.secrets.ssh_key_tongfang_testuser = {
    file = ../../secrets/ssh_key_tongfang_key_testuser.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
}
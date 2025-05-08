{ config, pkgs, ... }:

{
  age.secrets.ssh_key_singer_eelco = {
    file = ../../secrets/ssh_key_singer_eelco.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
  age.secrets.ssh_key_singer_testuser = {
    file = ../../secrets/ssh_key_singer_testuser.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
  age.secrets.ssh_key_singer_por = {
    file = ../../secrets/ssh_key_singer_por.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
}
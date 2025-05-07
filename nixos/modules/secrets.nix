{ config, pkgs, ... }:

{
  age.secrets.ssh_key_generic_vm_eelco = {
    file = ../secrets/ssh_key_generic_vm_key_eelco.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
  age.secrets.ssh_key_generic_vm_testuser = {
    file = ../secrets/ssh_key_generic_vm_key_testuser.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
  age.secrets.ssh_key_tongfang_eelco = {
    file = ../secrets/ssh_key_tongfang_key_eelco.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
  age.secrets.ssh_key_tongfang_testuser = {
    file = ../secrets/ssh_key_tongfang_key_testuser.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
  age.secrets.ssh_key_singer_eelco = {
    file = ../secrets/ssh_key_singer_key_eelco.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
  age.secrets.ssh_key_singer_testuser = {
    file = ../secrets/ssh_key_singer_key_testuser.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
  age.secrets.ssh_key_singer_por = {
    file = ../secrets/ssh_key_singer_key_por.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
  };
}
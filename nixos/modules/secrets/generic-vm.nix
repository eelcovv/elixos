{ config, pkgs, ... }:

{
  age.secrets.ssh_key_generic_vm_eelco = {
    file = ../../secrets/ssh_key_generic_vm_eelco.age;
    owner = "eelco";
    group = "users";
    mode = "0600";
    path = "/home/eelco/.ssh/id_ed25519";
  };
}
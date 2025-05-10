{
  age.secrets.ssh_key_generic_vm_eelco = {
    file = ../../secrets/ssh_key_generic_vm_eelco.age;
    owner = "root";
    group = "root";
    mode = "0400";
    # Niet direct naar /home/eelco schrijven!
    # Bewaar onder /run/agenix en symlink later
  };
}
{ pkgs, ... }:

{
  users.users.testuser = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = "$6$HueeKpsiCsngYXdl$DUHJZx8Hw9/WcNY/b22fA7rDXBRpdiBW/G0t9.Nrx30i.6iLRkJWYh2Fh306aKVZ6MkOFjXUcTe8Au.dsPJTF1"
  };
}

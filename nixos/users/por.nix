{
  pkgs,
  config,
  lib,
  ...
}: {
  users.users.por = {
    isNormalUser = true;
    createHome = true;
    home = "/home/por";
    description = "Karnrawee van Vliet";
    extraGroups = ["wheel" "networkmanager" "audio" "elixos"];
    hashedPassword = "$6$V.Q6S5VyKvJeWOsL$c2GXEqsgBP4NocBElNAcYYV8dILH4lr3axyN9s2E5v/fhEcH/S9y/LzLxeGth6KbTEHa3LyJpKmaedKzxqCWm/";
    shell = pkgs.zsh;
  };
}

{ pkgs, ... }:

{
  users.users.por = {
      isNormalUser = true;
      description = "Por Mangkang";
      extraGroups = [ "wheel" "networkmanager" "audio" ];
      hashedPassword = "$6$V.Q6S5VyKvJeWOsL$c2GXEqsgBP4NocBElNAcYYV8dILH4lr3axyN9s2E5v/fhEcH/S9y/LzLxeGth6KbTEHa3LyJpKmaedKzxqCWm/"
      shell = pkgs.zsh;
  };
}

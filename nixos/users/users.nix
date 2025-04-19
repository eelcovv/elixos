{ pkgs, ... }:

{
  users.users = {
    eelco = {
      isNormalUser = true;
      description = "Eelco van Vliet";
      extraGroups = [ "wheel" "networkmanager" "audio" ];
      hashedPassword = "<hier jouw hashed wachtwoord>";
      shell = pkgs.zsh;
    };

    # Optioneel meer gebruikers:
    testuser = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = "<test hashed wachtwoord>";
    };
  };
}

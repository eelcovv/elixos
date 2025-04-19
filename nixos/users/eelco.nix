{ pkgs, ... }:

{
  users.users.eelco = {
      isNormalUser = true;
      description = "Eelco van Vliet";
      extraGroups = [ "wheel" "networkmanager" "audio" ];
      hashedPassword = "$6$/BFpWvnMkSUI03E7$wZPqzCZIVxEUdf1L46hkAL.ifLlW61v4iZvWCh9MC5X9UGbRPadOg43AJrw4gfRgWwBRt0u6UxIgmuZ5KuJFo.";
      shell = pkgs.zsh;
  };
}

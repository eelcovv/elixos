{ pkgs, config, ... }:

{
  users.users.eelco = {
    isNormalUser = true;
    createHome = true;
    home = "/home/eelco";
    description = "Eelco van Vliet";
    extraGroups = [ "wheel" "networkmanager" "audio" ];
    group = "eelco";  # Force private group
    hashedPassword = "$6$/BFpWvnMkSUI03E7$wZPqzCZIVxEUdf1L46hkAL.ifLlW61v4iZvWCh9MC5X9UGbRPadOg43AJrw4gfRgWwBRt0u6UxIgmuZ5KuJFo.";
    shell = pkgs.zsh;
  };
}

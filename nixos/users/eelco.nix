# nixos/users/eelco.nix
{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./authorized_keys.nix
  ];

  # sops-nix config: pad naar age keyfile
  sops.age.keyFile = "/etc/sops/age/keys.txt";

  users.users.eelco = {
    isNormalUser = true;
    createHome = true;
    home = "/home/eelco";
    description = "Eelco van Vliet";
    extraGroups = ["wheel" "networkmanager" "audio" "elixos" "docker" "scanner" "lp"];
    hashedPassword = "$6$/BFpWvnMkSUI03E7$wZPqzCZIVxEUdf1L46hkAL.ifLlW61v4iZvWCh9MC5X9UGbRPadOg43AJrw4gfRgWwBRt0u6UxIgmuZ5KuJFo.";
    shell = pkgs.zsh;

    # authorized_keys: fallback op lege lijst als niet gedefinieerd
    openssh.authorizedKeys.keys = config.authorizedKeys.perUser.eelco or [];

    # Rootless Podman user-namespace mapping
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  # Als je authorized_keys module tmpfiles rules levert: robust fallback
  systemd.tmpfiles.rules = config.authorizedKeys.tmpfilesRules or [];
}

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

  users.users.eelco = {
    isNormalUser = true;
    createHome = true;
    home = "/home/eelco";
    description = "Eelco van Vliet";
    extraGroups = ["wheel" "networkmanager" "audio" "elixos"];
    hashedPassword = "$6$/BFpWvnMkSUI03E7$wZPqzCZIVxEUdf1L46hkAL.ifLlW61v4iZvWCh9MC5X9UGbRPadOg43AJrw4gfRgWwBRt0u6UxIgmuZ5KuJFo.";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = config.authorizedKeys.perUser.eelco;

    # Enable subordinate ID ranges for rootless Podman user namespaces
    subUidRanges = [
      {
        start = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        start = 100000;
        count = 65536;
      }
    ];
  };

  systemd.tmpfiles.rules = config.authorizedKeys.tmpfilesRules;

  # (Optional) Ensure unprivileged user namespaces are allowed (usually default true)
  security.unprivilegedUsernsClone = true;
}

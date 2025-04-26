/*
  This NixOS configuration file defines the system settings for the "tongfang" host.

  - `imports`: Includes additional Nix modules for modular configuration:
  - `../modules/common.nix`: Common configurations shared across systems.
  - `../hardware/tongfang.nix`: Hardware-specific configurations for the "tongfang" machine.
  - `../users/eelco.nix`: User-specific configuration for "eelco".
  - `../users/testuser.nix`: User-specific configuration for "testuser".

  - `networking.hostName`: Sets the hostname of the system to "tongfang".

  - `system.stateVersion`: Specifies the NixOS state version, ensuring compatibility with NixOS 24.05.
*/
{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../hardware/tongfang.nix
    ../users/eelco.nix
    ../users/testuser.nix
  ];

  networking.hostName = "tongfang";
  system.stateVersion = "24.05";
}

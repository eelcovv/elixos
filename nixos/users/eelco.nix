/**
 * This NixOS module defines the configuration for the user "eelco".
 *
 * Parameters:
 * - `pkgs`: The set of available Nix packages.
 * - `config`: The system configuration.
 * - `...`: Additional arguments.
 *
 * Let bindings:
 * - `hostSpecificKeys`: A set of SSH public keys specific to different hostnames.
 * - `keys`: The SSH keys corresponding to the current hostname, derived from `hostSpecificKeys`.
 *
 * Configuration:
 * - `users.users.eelco`: Defines the user "eelco" with the following properties:
 *   - `isNormalUser`: Indicates that this is a normal user.
 *   - `description`: A description for the user.
 *   - `extraGroups`: Additional groups the user belongs to, such as "wheel", "networkmanager", and "audio".
 *   - `hashedPassword`: The hashed password for the user.
 *   - `shell`: Specifies the user's shell, set to Zsh from the package set.
 *   - `openssh.authorizedKeys.keys`: Configures the SSH authorized keys for the user, based on the current hostname.
 */
{ pkgs, config, ... }:

let
  hostSpecificKeys = {
    "tongfang" = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
    ];
    "tongfang-vm" = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@vm"
    ];
    # eventueel meer hosts...
  };
  keys = hostSpecificKeys.${config.networking.hostName} or [];
in
{
  users.users.eelco = {
    isNormalUser = true;
    createHome = true;
    description = "Eelco van Vliet";
    extraGroups = [ "wheel" "networkmanager" "audio" ];
    hashedPassword = "$6$/BFpWvnMkSUI03E7$wZPqzCZIVxEUdf1L46hkAL.ifLlW61v4iZvWCh9MC5X9UGbRPadOg43AJrw4gfRgWwBRt0u6UxIgmuZ5KuJFo.";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = keys;

  };

}

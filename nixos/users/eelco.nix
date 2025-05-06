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
{ pkgs, config, lib, ... }:

{
  services.openssh.enable = true;

  users.users.eelco = {
    isNormalUser = true;
    createHome = true;
    home = "/home/eelco";
    shell = pkgs.zsh;

    # 🔑 DIRECT de key hier zetten, zonder optie-module
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
    ];
  };
}

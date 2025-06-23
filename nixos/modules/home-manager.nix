{ config, lib, pkgs, inputs, ... }:

let
  # Pad naar de gebruikersconfiguraties
  userPath = ../../home/users;

  # Genereer een attribuutset van alle gebruikers in `configuredUsers`
  userConfigs = lib.genAttrs config.configuredUsers (user:
    let
      path = userPath + "/${user}.nix";
    in
      if builtins.pathExists path then import (toString path)
      else throw "Home Manager config not found for user '${user}' at ${toString path}"
  );
in
{
  # Home Manager integratie met NixOS
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # Alleen voor opgegeven gebruikers
  home-manager.users = userConfigs;
}


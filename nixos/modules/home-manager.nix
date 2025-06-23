{ config, lib, pkgs, inputs, userModulesPath, ... }:

let
  userConfigs = lib.genAttrs config.configuredUsers (user:
    let
      path = userModulesPath + "/${user}.nix";
    in
      if builtins.pathExists path then import (toString path)
      else throw "Home Manager config not found for user '${user}' at ${toString path}"
  );
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users = userConfigs;
}

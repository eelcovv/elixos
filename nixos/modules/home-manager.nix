{
  config,
  lib,
  pkgs,
  inputs,
  userModulesPath,
  ...
}: let
  users = config.configuredUsers or [];

  userConfigs = lib.genAttrs users (user: {
    imports = [(userModulesPath + "/${user}.nix")];
  });
in {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users = userConfigs;
}

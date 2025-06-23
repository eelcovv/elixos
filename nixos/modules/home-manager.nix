{ config, lib, pkgs, inputs, ... }: {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users = lib.mkMerge [
    (lib.mkIf (config.users.users ? eelco) {
      eelco = import ../../home/users/eelco.nix;
    })
    (lib.mkIf (config.users.users ? por) {
      por = import ../../home/users/por.nix;
    })
  ];
}

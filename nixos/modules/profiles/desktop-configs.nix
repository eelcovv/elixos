{ config, lib, pkgs, ... }:

{
  config = lib.mkMerge (
    lib.optional config.desktop.enableGnome (import ./gnome.nix { inherit pkgs lib; }) ++
    lib.optional config.desktop.enableKde (import ./kde.nix { inherit pkgs lib; }) ++
    lib.optional config.desktop.enableHyperland (import ./hyperland.nix { inherit pkgs lib; })
  );
}


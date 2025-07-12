{ config, lib, pkgs, ... }:

let
  gnome = import ./gnome.nix;
  kde = import ./kde.nix;
  hyperland = import ./hyperland.nix;
in
{
  config = lib.mkMerge (
    lib.optional config.desktop.enableGnome (gnome { inherit config lib pkgs; }) ++
    lib.optional config.desktop.enableKde (kde { inherit config lib pkgs; }) ++
    lib.optional config.desktop.enableHyperland (hyperland { inherit config lib pkgs; })
  );
}

{ config, lib, ... }:

{
  imports = lib.concatLists [
    (lib.optional config.desktop.enableGnome ./gnome.nix)
    (lib.optional config.desktop.enableKde ./kde.nix)
    (lib.optional config.desktop.enableHyperland ./hyperland.nix)
  ];
}

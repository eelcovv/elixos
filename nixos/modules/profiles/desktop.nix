{ config, lib, ... }:

{
  options.desktop = {
    enableGnome = lib.mkEnableOption "Enable GNOME desktop";
    enableKde = lib.mkEnableOption "Enable KDE Plasma desktop";
    enableHyperland = lib.mkEnableOption "Enable Hyperland desktop";
  };

  config.imports = lib.concatLists [
    (lib.optional config.desktop.enableGnome ./gnome.nix)
    (lib.optional config.desktop.enableKde ./kde.nix)
    (lib.optional config.desktop.enableHyperland ./hyperland.nix)
  ];
}


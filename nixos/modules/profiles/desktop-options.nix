{ lib, ... }:

{
  options.desktop = {
    enableGnome = lib.mkEnableOption "Enable GNOME desktop";
    enableKde = lib.mkEnableOption "Enable KDE Plasma desktop";
    enableHyperland = lib.mkEnableOption "Enable Hyperland desktop";
  };
}

{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    imagemagick
    krita
    gimp
    inkscape
  ];
}

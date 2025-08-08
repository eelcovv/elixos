{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    imagemagick
    graphicsmagick
    krita
    gimp
    inkscape
  ];
}

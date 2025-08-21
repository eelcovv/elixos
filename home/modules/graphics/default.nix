{
  config,
  pkgs,
  lib,
  ...
}: {
  #imports = [
  #  ./ptgui
  #];
  home.packages = with pkgs; [
    imagemagick
    inkscape-with-extensions
    gimp
    graphicsmagick
    krita
  ];
}

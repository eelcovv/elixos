{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./ptgui
  ];
  home.packages = with pkgs; [
    drawio
    gimp
    graphicsmagick
    grim
    imagemagick
    inkscape-with-extensions
    krita
    slurp
    swappy
    wl-clipboard
  ];
}

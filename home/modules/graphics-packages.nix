{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./graphics/ptgui
  ];
  home.packages = with pkgs; [
    imagemagick
    graphicsmagick
    krita
    gimp
  ];
}

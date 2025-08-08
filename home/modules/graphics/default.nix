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
    imagemagick
    graphicsmagick
    krita
    gimp
  ];
}

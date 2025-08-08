{ pkgs, ... }:
{
  home.packages = with pkgs; [
    texliveFull
    inkscape-with-extensions
  ];
}

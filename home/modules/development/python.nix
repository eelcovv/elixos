{ pkgs, ... }:
{
  home.packages = with pkgs; [
    uv
    twine
    poetry
  ];
}

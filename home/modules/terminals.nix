{
  config,
  pkgs,
  lib,
  ...
}: {
  # note that we import zsh via users
  imports = [
    ./terminals/kitty
    ./terminals/alacritty
    ./terminals/foot
  ];


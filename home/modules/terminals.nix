{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./terminals/kitty
    ./terminals/alacritty
    ./terminals/foot
  ];
}

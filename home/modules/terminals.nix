{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./terminals/alacritty
    ./terminals/foot
    ./terminals/kitty
    ./terminals/wezterm
  ];
}

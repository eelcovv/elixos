{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./alacritty
    ./foot
    ./kitty
    ./wezterm
  ];
}

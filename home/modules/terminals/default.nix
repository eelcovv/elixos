{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./alacritty
    ./foot
    ./ghostty
    ./kitty
    ./wezterm
  ];
}

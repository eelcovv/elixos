{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./vim
    ./nvim
  ];

  home.packages = with pkgs; [
    gedit # GNOME's simple text editor
  ];
}

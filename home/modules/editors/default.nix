{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./vim
    ./nvim
    ./zed
  ];

  home.packages = with pkgs; [
    gedit # GNOME's simple text editor
    sublime
  ];
}

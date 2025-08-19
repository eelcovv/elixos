{
  config,
  pkgs,
  lib,
  ...
}: let
  wpDir = "${config.xdg.configHome}/wallpapers";
  wpRepoUrl = "https://github.com/mylinuxforwork/wallpaper";
  wpRepoBranch = "main";
in {
  home.packages = with pkgs; [git rsync];
}

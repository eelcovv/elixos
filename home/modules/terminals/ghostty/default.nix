{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
    settings = {
      gtk-titlebar = true; # better on tiling wm
      font-size = 10;
      theme = "catppuccin-mocha";
    };
  };
}

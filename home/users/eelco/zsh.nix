{
  config,
  pkgs,
  lib,
  ...
}:
import ../../modules/shells/zsh.nix {
  inherit config pkgs lib;
  promptStyle = "ohmyposh"; # hier kies je het thema
}

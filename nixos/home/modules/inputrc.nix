{ config, lib, pkgs, ... }:

{
  home.file.".inputrc".text = ''
    set editing-mode vi
    set show-all-if-ambiguous on
    TAB: menu-complete
  '';
}

{ lib, pkgs, ... }:

{
  #
  # Custom MIME type associations
  #
  # See https://wiki.archlinux.org/title/XDG_MIME_Applications
  #
  xdg.mime.addedAssociations = {
    "application/vnd.jgraph.mxfile" = [ "drawio.desktop" ];
    "application/x-drawio" = [ "drawio.desktop" ];
  };
}

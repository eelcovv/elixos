# nixos/modules/lib/python-runtimes.nix (minimal compat)
{
  pkgs,
  lib,
  ...
}: {
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    glibc
    zlib
    glib
    openssl
    expat
    icu
    fontconfig
    freetype
    harfbuzz
    libpng
    libjpeg
    libtiff
    e2fsprogs
  ];
}

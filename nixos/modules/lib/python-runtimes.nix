# nixos/modules/lib/python-runtimes.nix
{
  pkgs,
  lib,
  ...
}: let
  libxshmfence_pkg = pkgs.xorg.libxshmfence or pkgs.libxshmfence;
in {
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    # C/C++
    stdenv.cc.cc.lib
    glibc
    gmp # libgmp.so.10  (pymeshlab plugins)
    p11-kit # libp11-kit.so.0 (e57 plugin chain)

    # GL/GLVND
    libglvnd
    libGL
    libGLU
    mesa
    libdrm

    # Wayland/X11
    wayland
    libxkbcommon
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    xorg.libXrender
    xorg.libXtst
    xorg.libXfixes
    xorg.libXcomposite
    xorg.libXext
    xorg.libXdamage
    xorg.libxcb
    xorg.libXinerama
    xorg.libXxf86vm
    libxshmfence_pkg

    # Core + fonts + codecs
    zlib
    glib
    openssl
    dbus
    expat
    icu
    fontconfig
    freetype
    harfbuzz
    libpng
    libjpeg
    libtiff

    # manylinux compat
    e2fsprogs
  ];
}

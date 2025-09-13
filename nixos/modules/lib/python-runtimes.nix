# nixos/modules/lib/python-runtimes.nix
{
  pkgs,
  lib,
  ...
}: let
  # Werkt op beide nixpkgs-varianten:
  # - pkgs.xorg.libxshmfence (meest voorkomend)
  # - pkgs.libxshmfence (sommige channels)
  libxshmfence_pkg = pkgs.xorg.libxshmfence or pkgs.libxshmfence;
in {
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    # C/C++
    stdenv.cc.cc.lib
    glibc
    gmp # libgmp.so.10 (pymeshlab plugins)
    p11-kit # libp11-kit.so.0 (e57 plugin chain)

    # GL/GLVND
    libglvnd
    libGL
    libGLU
    mesa
    libdrm

    # Wayland/X11 (uitgebreid voor Qt xcb plugin)
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

    # xcb-util stack die Qt’s xcb-platform plugin vaak nodig heeft
    xorg.xcbutil
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm

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

    # manylinux compat (libcom_err.so.3 → lokale alias naar .2 in je project)
    e2fsprogs
  ];
}

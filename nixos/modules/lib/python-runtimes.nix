# nixos/modules/lib/python-runtimes.nix
{
  pkgs,
  lib,
  ...
}: {
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    # C/C++
    stdenv.cc.cc.lib
    glibc

    # GL/GLVND (belangrijk voor libGL.so.1)
    libglvnd # <-- voegt libGL.so.1 en libEGL.so.1 toe
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
    e2fsprogs

    libkrb5

    libxshmfence

    vulkan-loader

    zstd
    bzip2
    xz
    curl
    nghttp2
    libpsl
    c-ares
    libuuid
    libcap
    libselinux
  ];
}

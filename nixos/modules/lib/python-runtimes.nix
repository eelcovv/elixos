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
    xorg.libXinerama # vaak nodig voor Qt/GL wheels
    xorg.libXxf86vm # idem
    xorg.libXshmfence # <-- correcte naam/namespace

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

    # Voor libcom_err.so.3 (compat met manylinux wheels)
    e2fsprogs

    # (optioneel, maar nuttig bij netwerk/wheels)
    # curl nghttp2 libpsl c-ares zstd xz bzip2
    # krb5
  ];
}

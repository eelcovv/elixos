# nixos/modules/lib/python-runtimes.nix
{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.nix-ld = {
    enable = true;

    # De libraries die jouw wheels (matplotlib/numpy/scipy/qt/etc.) nodig hebben.
    libraries = with pkgs; [
      # C/C++
      stdenv.cc.cc.lib
      glibc

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

      # OpenGL / GLVND
      libGL
      libGLU
      mesa
      libdrm

      # Wayland
      wayland
      libxkbcommon

      # X11 + XCB
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
      xorg.xcbutil
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilwm
      xorg.xcbutilrenderutil

      # SciPy / NumPy runtimes
      openblas
      gfortran.cc.lib
      (lib.getOutput "lib" util-linux) # libuuid.so.1
    ];
  };
}

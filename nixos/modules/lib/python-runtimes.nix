# nixos/modules/lib/python-runtimes.nix
{
  pkgs,
  lib,
  ...
}: {
  programs.nix-ld = {
    enable = true;

    # Tip: stdenv.cc.cc.lib levert libstdc++.so.6 en libgcc_s.so.1
    # glibc levert libc.so.6
    libraries = with pkgs; [
      # C/C++ runtime
      stdenv.cc.cc.lib
      glibc

      # Core
      zlib
      glib
      openssl
      dbus # libdbus-1.so.3
      expat
      icu

      # Fonts & text shaping
      fontconfig
      freetype
      harfbuzz

      # Image codecs
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

      # Wetenschappelijke stacks (NumPy/SciPy) hebben vaak dit nodig:
      openblas # BLAS/LAPACK
      (lib.getOutput "lib" util-linux) # libuuid.so.1 voor o.a. Matplotlib op sommige wheels

      # Als je Fortran-runtime nodig hebt (SciPy e.d.):
      # (laat gerust staan; ontbreekt het attribuut, dan kun je het weghalen)
      # gfortran.cc.lib

      # Vulkan indien nodig:
      # vulkan-loader
    ];
  };
}

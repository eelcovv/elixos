{
  pkgs,
  lib,
  ...
}: {
  programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      # C/C++ runtime
      gcc.cc.lib
      stdenv.cc.cc.lib
      glibc

      # Core
      zlib
      glib
      openssl
      dbus

      # Fonts & shaping
      fontconfig
      freetype
      harfbuzz
      expat
      icu

      # Codecs / beeld
      libpng
      libjpeg
      libtiff

      # OpenGL / GPU
      libGL
      libGLU
      mesa
      libdrm

      # Wayland
      wayland
      libxkbcommon

      # X11/XCB
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

      # Veel wheels verwachten libuuid.so.1
      (lib.getOutput "lib" util-linux)

      # Voeg alleen toe als je ze écht nodig hebt (meestal niet voor wheels):
      # gfortran.cc.lib
      # openblas
      # vulkan-loader
    ];
  };
}

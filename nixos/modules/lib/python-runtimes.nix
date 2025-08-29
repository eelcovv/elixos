{
  pkgs,
  lib,
  ...
}:
# nixos/modules/lib/python-runtimes.nix
{
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
      dbus # <- provides libdbus-1.so.3

      # Fonts & text shaping
      fontconfig
      freetype
      harfbuzz
      expat
      icu

      # Image codecs
      libpng
      libjpeg
      libtiff

      # OpenGL / GLVND
      libGL
      libGLU
      mesa
      libdrm # common GPU userspace (harmless to include)

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

      # Optional if encountered:
      # gfortran.cc.lib
      # vulkan-loader
    ];
  };
}

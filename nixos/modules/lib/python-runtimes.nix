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

      # Core
      zlib
      glib
      openssl
      fontconfig
      freetype
      harfbuzz
      expat
      icu
      libpng
      libjpeg
      libtiff

      # OpenGL / GLVND
      libGL # <- provides libGL.so.1 (via libglvnd)
      glu # <- provides libGLU.so.1 (some Qt paths still expect it)
      mesa # generic GL stack bits; fine to keep

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

      # Optional:
      # gfortran.cc.lib
      # vulkan-loader
    ];
  };
}

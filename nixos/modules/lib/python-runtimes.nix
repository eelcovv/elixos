{
  pkgs,
  lib,
  ...
}:
# nixos/modules/lib/python-runtimes.nix
# System-wide nix-ld config so foreign Python wheels (NumPy, PySide6, Matplotlib, …)
# can find common system libraries (libstdc++, libGL.so.1, XCB, Wayland, …).
{
  programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      # C/C++ runtime
      gcc.cc.lib # libstdc++.so.6, libgcc_s.so.1

      # Core
      zlib
      glib
      openssl

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
      libGL # provides libGL.so.1 (via libglvnd/mesa)
      libGLU # provides libGLU.so.1 (some Qt paths still expect it)
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

      # Optional if you encounter them:
      # gfortran.cc.lib          # libgfortran.so.*
      # vulkan-loader
    ];
  };
}

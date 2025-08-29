{
  pkgs,
  lib,
  ...
}:
# Nix-ld runtime support for non-Nix Python wheels (NumPy, PySide6, Matplotlib, etc.)
# Exposes common system libraries so prebuilt wheels can link correctly on NixOS.
{
  programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      # C/C++ runtime
      stdenv.cc.cc.lib # libstdc++.so.6, libgcc_s.so.1

      # Core compression/crypto/glib
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

      # Graphics/GL
      mesa

      # Wayland stack
      wayland
      libxkbcommon

      # X11 stack (Qt/Matplotlib often benefit from xcb fallback)
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

      # XCB utils (note the xorg.* prefixes)
      xorg.libxcb
      xorg.xcbutil
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilwm
      xorg.xcbutilrenderutil

      # Optional additions if needed by specific wheels:
      # gfortran.cc.lib   # libgfortran.so.* (Fortran-backed wheels)
      # vulkan-loader     # if you run Vulkan-backed apps/libraries
    ];
  };
}

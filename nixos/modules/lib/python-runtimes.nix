{
  pkgs,
  lib,
  ...
}:
# nixos/modules/lib/python-runtimes.nix
# System-wide nix-ld config so foreign Python wheels (NumPy, PySide6, …)
# can find common system libraries (libstdc++, zlib, XCB, Wayland, …).
{
  programs.nix-ld = {
    enable = true;

    # Keep this focused on runtime libs (no full apps here).
    libraries = with pkgs; [
      # C/C++ runtime: use GCC's libstdc++ explicitly
      gcc.cc.lib # <- provides libstdc++.so.6 and libgcc_s.so.1

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

      # X11 stack (xcb fallback is often needed by Qt/Matplotlib)
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

      # XCB utils (note xorg.* prefixes)
      xorg.libxcb
      xorg.xcbutil
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilwm
      xorg.xcbutilrenderutil

      # Uncomment if you hit these deps:
      # gfortran.cc.lib          # libgfortran.so.* (Fortran-backed wheels)
      # vulkan-loader            # for Vulkan-backed libs/apps
    ];
  };
}

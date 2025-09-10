# nixos/modules/lib/python-runtimes.nix
{
  pkgs,
  lib,
  ...
}: {
  programs.nix-ld = {
    enable = true;

    # Runtimes that many Python (uv/pip) wheels need at runtime.
    libraries = with pkgs; [
      # C/C++ runtime
      stdenv.cc.cc.lib # libstdc++.so.6, libgcc_s.so.1
      glibc # libc.so.6

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
      gfortran.cc.lib # libgfortran.so.*, libquadmath.so.0
      (lib.getOutput "lib" util-linux) # libuuid.so.1
    ];
  };
}

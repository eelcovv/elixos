{
  pkgs,
  lib,
  ...
}: {
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # libstdc++.so.6 / libgcc_s.so.1
      zlib
      glib
      fontconfig
      freetype
      harfbuzz
      expat
      icu
      openssl
      libpng
      libjpeg
      libtiff
      mesa
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
      libxcb
      xcbutil
      xcbutilimage
      xcbutilkeysyms
      xcbutilwm
      # Optioneel als je het tegenkomt:
      # gfortran.cc.lib  # voor libgfortran.so
      # vulkan-loader
    ];
  };
}

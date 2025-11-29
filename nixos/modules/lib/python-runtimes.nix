{
  pkgs,
  lib,
  ...
}: {
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries =
    (with pkgs; [
      # basis
      stdenv.cc.cc.lib
      glibc
      zlib
      glib
      openssl
      expat
      icu
      fontconfig
      freetype
      harfbuzz
      libpng
      libjpeg
      libtiff
      e2fsprogs

      # OpenGL (for VTK, pymeshlab, eventueel Qt)
      libglvnd
      libdrm

      # Wayland/X11/XCB for Qt (PySide6)
      wayland
      libxkbcommon
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libXfixes
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXinerama
      xorg.libXdamage
      xorg.libXcomposite
      xorg.libXi
      xorg.libXtst
      xorg.libxcb
      xorg.xcbutil
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilwm

      dbus
    ])
    # optional libs: add only if they exist in your nixpkgs
    ++ lib.optional (pkgs ? xorg.xcbutilcursor) pkgs.xorg.xcbutilcursor
    ++ lib.optional (pkgs ? libxshmfence) pkgs.libxshmfence;

  # Convenient to Wayland; Qt falls back to xcb if Wayland fails
  environment.sessionVariables.QT_QPA_PLATFORM = "wayland;xcb";
}

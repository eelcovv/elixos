{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.pythonRtLibs;
in {
  options.pythonRtLibs = {
    enable = lib.mkEnableOption "Install common runtime libs for Python (Qt/PySide6, OpenGL, fonts, X11/Wayland)";
    withQtDev = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include PySide6 + shiboken6 (useful for Qt-based Python apps).";
    };
    withX11 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include X11 client libs.";
    };
    withWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include Wayland client libs and Qt Wayland platform plugins.";
    };
    withVulkan = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include Vulkan loader (if you need it).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = let
      qtPkgs = lib.optionals cfg.withQtDev (
        [pkgs.pyside6 pkgs.shiboken6]
        ++ lib.optionals cfg.withWayland [pkgs.qt6.qtwayland]
      );

      x11Pkgs = lib.optionals cfg.withX11 [
        pkgs.xorg.libX11
        pkgs.xorg.libXcursor
        pkgs.xorg.libXrandr
        pkgs.xorg.libXi
        pkgs.xorg.libXrender
        pkgs.xorg.libXtst
        pkgs.xorg.libXfixes
        pkgs.xorg.libXcomposite
        pkgs.xorg.libXext
        pkgs.xorg.libXdamage
        pkgs.libxcb
        pkgs.xcbutil
        pkgs.xcbutilimage
        pkgs.xcbutilkeysyms
        pkgs.xcbutilwm
      ];

      waylandPkgs = lib.optionals cfg.withWayland [
        pkgs.wayland
        pkgs.wayland-protocols
        pkgs.libxkbcommon
      ];

      baseRt =
        [
          pkgs.mesa
          pkgs.alsa-lib
          pkgs.pipewire
          pkgs.fontconfig
          pkgs.freetype
          pkgs.harfbuzz
          pkgs.zlib
          pkgs.glib
          pkgs.stdenv.cc.cc.lib # libstdc++.so.6 / libgcc_s.so.1
          pkgs.expat # veel native wheels verwachten expat
          pkgs.icu # Qt/Matplotlib hebben vaak ICU nodig
          pkgs.pcre
          pkgs.openssl
          pkgs.libpng
          pkgs.libjpeg
          pkgs.libtiff
          pkgs.ffmpeg
        ]
        ++ lib.optionals cfg.withVulkan [pkgs.vulkan-loader];
    in
      qtPkgs ++ x11Pkgs ++ waylandPkgs ++ baseRt;

    # Qt runtime pad (goed voor PySide6/Matplotlib-Qt)
    home.sessionVariables = {
      QT_QPA_PLATFORM = lib.mkDefault (
        if cfg.withWayland && cfg.withX11
        then "wayland;xcb"
        else if cfg.withWayland
        then "wayland"
        else "xcb"
      );
      QT_PLUGIN_PATH = lib.mkDefault "${pkgs.qt6.qtbase.bin}/lib/qt-6/plugins";
      QML2_IMPORT_PATH = lib.mkDefault "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml";

      # Als je (nog) geen system-wide nix-ld gebruikt, helpt dit:
      # Let op: LD_LIBRARY_PATH is een ‘big hammer’; nix-ld is netter.
      LD_LIBRARY_PATH = lib.mkDefault (lib.makeLibraryPath (
        [
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
          pkgs.glib
          pkgs.fontconfig
          pkgs.freetype
          pkgs.harfbuzz
          pkgs.expat
          pkgs.icu
          pkgs.openssl
          pkgs.libpng
          pkgs.libjpeg
          pkgs.libtiff
          pkgs.mesa
        ]
        ++ (
          if cfg.withX11
          then [
            pkgs.xorg.libX11
            pkgs.xorg.libXcursor
            pkgs.xorg.libXrandr
            pkgs.xorg.libXi
            pkgs.xorg.libXrender
            pkgs.xorg.libXtst
            pkgs.xorg.libXfixes
            pkgs.xorg.libXcomposite
            pkgs.xorg.libXext
            pkgs.xorg.libXdamage
            pkgs.libxcb
            pkgs.xcbutil
            pkgs.xcbutilimage
            pkgs.xcbutilkeysyms
            pkgs.xcbutilwm
          ]
          else []
        )
        ++ (
          if cfg.withWayland
          then [
            pkgs.wayland
            pkgs.libxkbcommon
          ]
          else []
        )
        ++ (
          if cfg.withVulkan
          then [pkgs.vulkan-loader]
          else []
        )
      ));
    };
  };
}

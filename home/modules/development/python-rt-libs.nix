# home/modules/development/python-rt-libs.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.pythonRtLibs;

  # Fallback naar python3Packages indien nodig
  pyPkgs =
    if builtins.hasAttr "python3Packages" pkgs
    then pkgs.python3Packages
    else pkgs.python3Packages;

  havePySide6 = builtins.hasAttr "pyside6" pyPkgs && builtins.hasAttr "shiboken6" pyPkgs;
in {
  options.pythonRtLibs = {
    enable = lib.mkEnableOption "Install common runtime libs for Python (Qt/PySide6, OpenGL, fonts, X11/Wayland)";

    # Gebruik uv voor PySide6 → laat default op false; zet true als je Qt uit Nix wil.
    withQtDev = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include PySide6 + shiboken6 from Nix.";
    };

    withX11 = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    withWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    withVulkan = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    # We exporteren GEEN LD_LIBRARY_PATH meer vanuit HM (gevaarlijk voor login).
    # BLAS/Fortran runtimes laat je door nix-ld regelen indien echt nodig — niet via HM-env.
  };

  config = lib.mkIf cfg.enable {
    home.packages = let
      qtPkgs =
        lib.optionals (cfg.withQtDev && havePySide6) [
          pyPkgs.pyside6
          pyPkgs.shiboken6
        ]
        ++ lib.optionals cfg.withWayland [pkgs.qt6.qtwayland];

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
        pkgs.xorg.xcbutil
        pkgs.xorg.xcbutilimage
        pkgs.xorg.xcbutilkeysyms
        pkgs.xorg.xcbutilwm
      ];

      waylandPkgs = lib.optionals cfg.withWayland [
        pkgs.wayland
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
          pkgs.stdenv.cc.cc.lib
          pkgs.expat
          pkgs.icu
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

    # Alleen Qt-gerelateerde variabelen; GEEN LD_LIBRARY_PATH hier.
    home.sessionVariables = {
      QT_QPA_PLATFORM = lib.mkDefault (
        if (cfg.withWayland && cfg.withX11)
        then "wayland;xcb"
        else if (cfg.withWayland)
        then "wayland"
        else "xcb"
      );

      # Gebruik lib-output voor robuuste paden
      QT_PLUGIN_PATH = lib.mkDefault "${lib.getLib pkgs.qt6.qtbase}/lib/qt-6/plugins";
      QML2_IMPORT_PATH = lib.mkDefault "${lib.getLib pkgs.qt6.qtdeclarative}/lib/qt-6/qml";
    };
  };
}

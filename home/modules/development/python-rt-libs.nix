# home/modules/development/python-rt-libs.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.pythonRtLibs;

  # Python package set (robust fallback)
  pyPkgs =
    if builtins.hasAttr "python3Packages" pkgs
    then pkgs.python3Packages
    else if builtins.hasAttr "python312Packages" pkgs
    then pkgs.python312Packages
    else pkgs.python3Packages;

  havePySide6 = builtins.hasAttr "pyside6" pyPkgs && builtins.hasAttr "shiboken6" pyPkgs;

  # Optional: for NumPy/SciPy wheels needing libgfortran
  haveGfortranLib =
    builtins.hasAttr "gfortran" pkgs
    && builtins.hasAttr "cc" pkgs.gfortran
    && builtins.hasAttr "lib" pkgs.gfortran.cc;
in {
  options.pythonRtLibs = {
    enable = lib.mkEnableOption "Install common runtime libs for Python (Qt/PySide6, OpenGL, fonts, X11/Wayland)";

    # Tip: gebruik uv voor PySide6 → laat deze UIT (false).
    withQtDev = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include PySide6 + shiboken6 from Nix (use only if you also use Nix' Python, not uv).";
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

    withBLAS = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include OpenBLAS runtime (useful for many scientific wheels).";
    };

    withFortranRuntime = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include libgfortran runtime if available (NumPy/SciPy wheels sometimes need this).";
    };

    useLdLibraryPath = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Export LD_LIBRARY_PATH with common runtimes. Set to false if you enable programs.nix-ld system-wide.";
    };

    extraLibraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional libraries to include in PATH/LD_LIBRARY_PATH (will also be added to home.packages).";
    };
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
          pkgs.expat
          pkgs.icu
          pkgs.pcre
          pkgs.openssl
          pkgs.libpng
          pkgs.libjpeg
          pkgs.libtiff
          pkgs.ffmpeg
        ]
        ++ lib.optionals cfg.withBLAS [pkgs.openblas]
        ++ lib.optionals (cfg.withFortranRuntime && haveGfortranLib) [pkgs.gfortran.cc.lib]
        ++ lib.optionals cfg.withVulkan [pkgs.vulkan-loader];
    in
      qtPkgs ++ x11Pkgs ++ waylandPkgs ++ baseRt ++ cfg.extraLibraries;

    # Qt runtime pad (goed voor PySide6/Matplotlib-Qt)
    home.sessionVariables =
      {
        QT_QPA_PLATFORM = lib.mkDefault (
          if cfg.withWayland && cfg.withX11
          then "wayland;xcb"
          else if cfg.withWayland
          then "wayland"
          else "xcb"
        );
        QT_PLUGIN_PATH = lib.mkDefault "${pkgs.qt6.qtbase.bin}/lib/qt-6/plugins";
        QML2_IMPORT_PATH = lib.mkDefault "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml";
      }
      // lib.optionalAttrs cfg.useLdLibraryPath {
        # Gebruik nix-ld system-wide? Zet useLdLibraryPath = false.
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
          ++ lib.optionals cfg.withBLAS [pkgs.openblas]
          ++ lib.optionals (cfg.withFortranRuntime && haveGfortranLib) [pkgs.gfortran.cc.lib]
          ++ lib.optionals cfg.withX11 [
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
          ++ lib.optionals cfg.withWayland [
            pkgs.wayland
            pkgs.libxkbcommon
          ]
          ++ lib.optionals cfg.withVulkan [pkgs.vulkan-loader]
          ++ cfg.extraLibraries
        ));
      };
  };
}

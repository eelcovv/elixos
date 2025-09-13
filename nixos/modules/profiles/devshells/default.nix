# nixos/modules/profiles/devshells/default.nix
{
  pkgs,
  inputs,
  system ? builtins.currentSystem,
  lib ? pkgs.lib,
  ...
}: let
  # Resolve nixGL packages for the current system (may fail on older Nix if currentTime is missing)
  nixGL =
    if builtins.hasAttr system inputs.nixgl.packages
    then inputs.nixgl.packages.${system}
    else inputs.nixgl.packages.${pkgs.system};

  # Some Nix versions don't have builtins.currentTime; nixGL relies on it.
  hasCurrentTime = builtins ? currentTime;

  # Only include nixGL wrappers when the builtin exists; otherwise we provide shell shims.
  nixGLWrappers =
    if hasCurrentTime
    then [nixGL.nixGLNvidia nixGL.nixGLIntel nixGL.nixVulkanNvidia]
    else [];
in {
  devShells = {
    py_light = pkgs.mkShell {
      packages = with pkgs; [python312 uv pre-commit];
      shellHook = ''
        echo "🐍 py_light active (python + uv, no compilers)"
      '';
    };

    py_build = pkgs.mkShell {
      packages = with pkgs; [python312 uv gcc gfortran cmake pkg-config openblas];
      shellHook = ''
        echo "🛠️  py_build active (gcc/gfortran/cmake/pkg-config/openblas)"
        echo "Use this shell for 'uv sync' when C/Fortran extensions are built."
      '';
    };

    # Guarded VTK/Qt/GL shell
    # py_vtk excerpt (English comments)
    py_vtk = pkgs.mkShell {
      packages = with pkgs; [
        python312
        uv
        vtk
        qt6.qtbase
        qt6.qtwayland

        mesa
        libglvnd
        wayland
        libxkbcommon

        # X11 stack
        xorg.libX11
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXi
        xorg.libXrender
        xorg.libXt
        xorg.libXmu
        xorg.libSM
        xorg.libICE
        xorg.libXtst
        xorg.libXfixes
        xorg.libXcomposite
        xorg.libXext
        xorg.libXdamage
        xorg.libxcb
        xorg.xcbutil
        xorg.xcbutilimage
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        xorg.xcbutilwm
        xorg.xcbutilcursor # <-- REQUIRED for Qt 6.5+ xcb platform plugin

        # Common runtime libs wheels need
        fontconfig
        freetype
        harfbuzz
        zlib
        glib
        openssl
        expat
        icu
        libpng
        libjpeg
        libtiff
        zstd
        dbus # we reference their lib dirs in LD_LIBRARY_PATH

        # Diag/tools
        mesa-demos
        patchelf
      ];

      shellHook = ''
        echo "🖼️  py_vtk active (Qt/VTK/OpenGL on NixOS)"
        # Try Wayland first, then fall back to XCB
        export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-wayland;xcb}"

        # Small helper to prepend to LD_LIBRARY_PATH
        prepend() { export LD_LIBRARY_PATH="$1''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"; }

        # Compat for manylinux wheels expecting libcom_err.so.2
        COMPAT_DIR="$PWD/.nix-ld-compat"
        mkdir -p "$COMPAT_DIR"
        ln -sf "${lib.getLib pkgs.e2fsprogs}/lib/libcom_err.so.3" "$COMPAT_DIR/libcom_err.so.2"
        prepend "$COMPAT_DIR"

        # GL + core libs
        prepend "${lib.getLib pkgs.libglvnd}/lib"      # libGL.so.1
        prepend "${lib.getLib pkgs.zlib}/lib"          # libz.so.1
        prepend "${lib.getLib pkgs.e2fsprogs}/lib"     # libcom_err.so.3
        prepend "${lib.getLib pkgs.expat}/lib"         # libexpat.so.1
        prepend "${lib.getLib pkgs.gmp}/lib"           # libgmp.so.10
        prepend "${lib.getLib pkgs.p11-kit}/lib"       # libp11-kit.so.0
        prepend "${lib.getLib pkgs.zstd}/lib"          # libzstd.so.1
        prepend "${lib.getLib pkgs.dbus}/lib"          # libdbus-1.so.3

        # X11 libs (incl. xcb-cursor)
        prepend "${lib.getLib pkgs.xorg.libX11}/lib"
        prepend "${lib.getLib pkgs.xorg.libXext}/lib"
        prepend "${lib.getLib pkgs.xorg.libXrender}/lib"
        prepend "${lib.getLib pkgs.xorg.libXrandr}/lib"
        prepend "${lib.getLib pkgs.xorg.libXi}/lib"
        prepend "${lib.getLib pkgs.xorg.libXt}/lib"
        prepend "${lib.getLib pkgs.xorg.libXmu}/lib"
        prepend "${lib.getLib pkgs.xorg.libSM}/lib"
        prepend "${lib.getLib pkgs.xorg.libICE}/lib"
        prepend "${lib.getLib pkgs.xorg.libxcb}/lib"
        prepend "${lib.getLib pkgs.xorg.xcbutil}/lib"
        prepend "${lib.getLib pkgs.xorg.xcbutilimage}/lib"
        prepend "${lib.getLib pkgs.xorg.xcbutilkeysyms}/lib"
        prepend "${lib.getLib pkgs.xorg.xcbutilrenderutil}/lib"
        prepend "${lib.getLib pkgs.xorg.xcbutilwm}/lib"
        prepend "${lib.getLib pkgs.xorg.xcbutilcursor}/lib"   # <-- new

        # Font/text stack needed by Qt
        prepend "${lib.getLib pkgs.fontconfig}/lib"
        prepend "${lib.getLib pkgs.freetype}/lib"
        prepend "${lib.getLib pkgs.harfbuzz}/lib"
        prepend "${lib.getLib pkgs.libpng}/lib"
        prepend "${lib.getLib pkgs.libjpeg}/lib"
        prepend "${lib.getLib pkgs.libtiff}/lib"
        prepend "${lib.getLib pkgs.glib}/lib"
        prepend "${lib.getLib pkgs.pcre2}/lib"
        prepend "${lib.getLib pkgs.libxkbcommon}/lib"
        prepend "${lib.getLib pkgs.wayland}/lib"
        prepend "${lib.getLib pkgs.openssl}/lib"
        prepend "${lib.getLib pkgs.icu}/lib"

        # NixOS vendor GL driver paths (no nixGL needed on NixOS)
        [ -d /run/opengl-driver/lib ]     && prepend "/run/opengl-driver/lib"
        [ -d /run/opengl-driver-32/lib ]  && prepend "/run/opengl-driver-32/lib"

        # Make sure Qt picks PySide6's bundled plugins first when VENV is active
        if [ -n "$VIRTUAL_ENV" ]; then
          wheel_plugins="$VIRTUAL_ENV/lib/python3.12/site-packages/PySide6/Qt/plugins"
          wheel_qml="$VIRTUAL_ENV/lib/python3.12/site-packages/PySide6/Qt/qml"
          if [ -d "$wheel_plugins" ]; then
            export QT_PLUGIN_PATH="$wheel_plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
          fi
          if [ -d "$wheel_qml" ]; then
            export QML2_IMPORT_PATH="$wheel_qml''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
          fi
        fi
        # Always include system Qt6 plugin/qml paths as fallback
        export QT_PLUGIN_PATH="${lib.getLib pkgs.qt6.qtbase}/lib/qt-6/plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
        export QML2_IMPORT_PATH="${lib.getLib pkgs.qt6.qtdeclarative}/lib/qt-6/qml''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"

        echo "Try: glxinfo -B"
      '';
    };
  };
}

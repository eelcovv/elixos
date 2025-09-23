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

    # VTK/Qt/GL shell tuned for wheels (PySide6 + VTK) on NixOS
    py_vtk = pkgs.mkShell {
      packages = with pkgs; [
        python312
        uv

        # VTK & Qt6 runtime
        vtk
        qt6.qtbase
        qt6.qtwayland
        qt6.qtdeclarative # QML + plugins used by many PySide6 wheels
        qt6.qtimageformats # common image plugins (png/jpg/webp/…)
        qt6.qtsvg # svg plugin used by many UIs

        # GL / windowing stacks
        mesa
        libglvnd
        wayland
        libxkbcommon

        # X11 stack (Qt may fall back to xcb even if Wayland is present)
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
        xorg.xcbutilcursor # Qt 6.5+ xcb plugin requires this

        # Common runtime libs manylinux wheels expect
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
        dbus
        pcre2

        # Diagnostics
        mesa-demos
        patchelf
      ];

      shellHook = ''
        echo "🖼️  py_vtk active (Qt/VTK/OpenGL on NixOS)"

        # ---- Backend selection -------------------------------------------------
        # Force X11/xcb for stability (mixed Qt5/Qt6 stacks and NVIDIA often prefer xcb).
        export QT_QPA_PLATFORM="xcb"
        export QT_XCB_GL_INTEGRATION="glx"      # optional, helps on NVIDIA
        export MPLBACKEND="${MPLBACKEND:-Agg}"  # optional, tames Matplotlib noise
        # You may temporarily enable deeper Qt plugin diagnostics:
        # export QT_DEBUG_PLUGINS=1

        # ---- Helper: prepend to LD_LIBRARY_PATH -------------------------------
        prepend() { export LD_LIBRARY_PATH="$1''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"; }

        # ---- Compat shims manylinux wheels expect -----------------------------
        COMPAT_DIR="$PWD/.nix-ld-compat"
        mkdir -p "$COMPAT_DIR"
        # libcom_err.so.2 is frequently expected by foreign wheels; symlink to .3
        ln -sf "${lib.getLib pkgs.e2fsprogs}/lib/libcom_err.so.3" "$COMPAT_DIR/libcom_err.so.2"
        prepend "$COMPAT_DIR"

        # ---- Core GL + base libs ----------------------------------------------
        prepend "${lib.getLib pkgs.libglvnd}/lib"      # libGL.so.1
        prepend "${lib.getLib pkgs.zlib}/lib"
        prepend "${lib.getLib pkgs.e2fsprogs}/lib"
        prepend "${lib.getLib pkgs.expat}/lib"
        prepend "${lib.getLib pkgs.gmp}/lib"
        prepend "${lib.getLib pkgs.p11-kit}/lib"
        prepend "${lib.getLib pkgs.zstd}/lib"
        prepend "${lib.getLib pkgs.dbus}/lib"

        # ---- X11 / xcb libs (incl. xcb-cursor) --------------------------------
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
        prepend "${lib.getLib pkgs.xorg.xcbutilcursor}/lib"

        # ---- Text / fonts / wayland / crypto / ICU ----------------------------
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

        # ---- Vendor GL driver paths on NixOS ----------------------------------
        [ -d /run/opengl-driver/lib ]     && prepend "/run/opengl-driver/lib"
        [ -d /run/opengl-driver-32/lib ]  && prepend "/run/opengl-driver-32/lib"

        # ---- Prefer wheel (PySide6) Qt over system Qt -------------------------
        # Many PySide6 wheels bundle their own Qt (Qt libs, plugins, qml).
        # We put wheel's Qt *first*, and only then fall back to system Qt.
        if [ -n "$VIRTUAL_ENV" ]; then
          pyver="$(python -c 'import sys;print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
          wheel_root="$VIRTUAL_ENV/lib/python$pyver/site-packages/PySide6/Qt"
          wheel_lib="$wheel_root/lib"
          wheel_plugins="$wheel_root/plugins"
          wheel_qml="$wheel_root/qml"

          # 1) Wheel Qt shared libs FIRST on LD_LIBRARY_PATH
          [ -d "$wheel_lib" ] && prepend "$wheel_lib"

          # 2) Reset plugin/qml paths to wheel FIRST (overwrite instead of prepend)
          if [ -d "$wheel_plugins" ]; then
            export QT_PLUGIN_PATH="$wheel_plugins"
          else
            unset QT_PLUGIN_PATH
          fi
          if [ -d "$wheel_qml" ]; then
            export QML2_IMPORT_PATH="$wheel_qml"
          else
            unset QML2_IMPORT_PATH
          fi

          # 3) Append system Qt as a fallback AFTER the wheel (safe)
          export QT_PLUGIN_PATH="''${QT_PLUGIN_PATH:+$QT_PLUGIN_PATH:}${lib.getLib pkgs.qt6.qtbase}/lib/qt-6/plugins"
          export QML2_IMPORT_PATH="''${QML2_IMPORT_PATH:+$QML2_IMPORT_PATH:}${lib.getLib pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
        else
          # No venv: use system Qt plugin/qml paths only
          export QT_PLUGIN_PATH="${lib.getLib pkgs.qt6.qtbase}/lib/qt-6/plugins"
          export QML2_IMPORT_PATH="${lib.getLib pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
        fi

        echo "Try: glxinfo -B"
      '';
    };
  };
}

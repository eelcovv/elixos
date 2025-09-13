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

        # Diagnostics
        mesa-demos
        patchelf
      ];

      shellHook = ''
        echo "🖼️  py_vtk active (Qt/VTK/OpenGL on NixOS)"

        # Prefer XCB while debugging plugin issues; switch back to 'wayland;xcb' later if you like
        export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-xcb}"

        # Helper to prepend to LD_LIBRARY_PATH
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
        prepend "${lib.getLib pkgs.xorg.xcbutilcursor}/lib"

        # Font/text stack for Qt
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

        # Vendor GL driver paths on NixOS
        [ -d /run/opengl-driver/lib ]     && prepend "/run/opengl-driver/lib"
        [ -d /run/opengl-driver-32/lib ]  && prepend "/run/opengl-driver-32/lib"

        # ── Critical: prefer wheel Qt (PySide6) over system Qt ───────────────────
        if [ -n "$VIRTUAL_ENV" ]; then
          wheel_root="$VIRTUAL_ENV/lib/python3.12/site-packages/PySide6/Qt"
          wheel_lib="$wheel_root/lib"
          wheel_plugins="$wheel_root/plugins"
          wheel_qml="$wheel_root/qml"

          # 1) Wheel Qt shared libs FIRST on LD_LIBRARY_PATH
          if [ -d "$wheel_lib" ]; then
            prepend "$wheel_lib"
          fi

          # 2) Reset plugin/qml paths to wheel FIRST (do not prepend system before wheel)
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

          # 3) Optionally append system Qt as a fallback AFTER the wheel (safe)
          export QT_PLUGIN_PATH="$QT_PLUGIN_PATH:${lib.getLib pkgs.qt6.qtbase}/lib/qt-6/plugins"
          export QML2_IMPORT_PATH="$QML2_IMPORT_PATH:${lib.getLib pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
        else
          # No venv: use system Qt plugin/qml paths
          export QT_PLUGIN_PATH="${lib.getLib pkgs.qt6.qtbase}/lib/qt-6/plugins"
          export QML2_IMPORT_PATH="${lib.getLib pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
        fi
        # ─────────────────────────────────────────────────────────────────────────

        echo "Try: glxinfo -B"
      '';
    };
  };
}

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

  # Keep Python build environment consistent with the *active* interpreter.
  python_consistency_hook = ''
    echo "🐍  Python consistency hook (config shim + clean env)"

    # Avoid leaking stdlib/site from host
    unset PYTHONHOME
    unset PYTHONPATH
    export PYTHONNOUSERSITE=1

    # On NixOS: never let uv download interpreters; use system only.
    export UV_PYTHON_DOWNLOADS="''${UV_PYTHON_DOWNLOADS:-never}"
    export UV_PYTHON_PREFER_SYSTEM=1

    # If a venv is active (e.g., created by uv), install a shim for python3-config
    if [ -n "$VIRTUAL_ENV" ]; then
      _pyver="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
      if [ -n "$_pyver" ] && command -v "python''${_pyver}-config" >/dev/null 2>&1; then
        mkdir -p "$VIRTUAL_ENV/bin"
        ln -sf "$(command -v python''${_pyver}-config)" "$VIRTUAL_ENV/bin/python3-config"
        export PATH="$VIRTUAL_ENV/bin:$PATH"
      fi
    else
      # No venv: prefer matching pythonX.Y-config if current python is X.Y
      _ver="$(python -V 2>/dev/null | awk '{print $2}' | cut -d. -f1,2)"
      case "$_ver" in
        3.11|3.12|3.13|3.14)
          if command -v "python''${_ver}-config" >/dev/null 2>&1; then
            _cfgdir="$(dirname "$(command -v python''${_ver}-config)")"
            export PATH="$_cfgdir:$PATH"
          fi
          ;;
      esac
    fi
  '';

  # Shared shellHook for Qt/VTK wheel-first setup.
  qt_wheel_shell_hook = lib: pkgs: ''
    echo "🖼️  Qt/VTK wheel env active"

    # Backend selection
    if [ -n "$PYTEST_CURRENT_TEST" ]; then
      export QT_QPA_PLATFORM="offscreen"
      unset QT_XCB_GL_INTEGRATION
    else
      export QT_QPA_PLATFORM="xcb"
      export QT_XCB_GL_INTEGRATION="glx"
    fi

    # Matplotlib: headless by default (escape $ for Nix)
    export MPLBACKEND="''${MPLBACKEND:-agg}"
    # export QT_DEBUG_PLUGINS=1  # optional

    # Helper
    prepend() { export LD_LIBRARY_PATH="$1''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"; }

    # manylinux compat
    COMPAT_DIR="$PWD/.nix-ld-compat"
    mkdir -p "$COMPAT_DIR"
    ln -sf "${lib.getLib pkgs.e2fsprogs}/lib/libcom_err.so.3" "$COMPAT_DIR/libcom_err.so.2"
    prepend "$COMPAT_DIR"

    # Core GL + base libs
    prepend "${lib.getLib pkgs.libglvnd}/lib"
    prepend "${lib.getLib pkgs.zlib}/lib"
    prepend "${lib.getLib pkgs.e2fsprogs}/lib"
    prepend "${lib.getLib pkgs.expat}/lib"
    prepend "${lib.getLib pkgs.gmp}/lib"
    prepend "${lib.getLib pkgs.p11-kit}/lib"
    prepend "${lib.getLib pkgs.zstd}/lib"
    prepend "${lib.getLib pkgs.dbus}/lib"

    # X11 / xcb
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

    # Fonts / text / wayland / crypto / ICU
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

    # Vendor GL drivers
    [ -d /run/opengl-driver/lib ]     && prepend "/run/opengl-driver/lib"
    [ -d /run/opengl-driver-32/lib ]  && prepend "/run/opengl-driver-32/lib"

    # Wheel-only Qt plugins
    export QT_NO_PLUGIN_LOOKUP=1

    if [ -n "$VIRTUAL_ENV" ]; then
      pyver="$(python -c 'import sys;print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
      wheel_root="$VIRTUAL_ENV/lib/python''${pyver:-3.12}/site-packages/PySide6/Qt"
      wheel_lib="$wheel_root/lib"
      wheel_plugins="$wheel_root/plugins"
      wheel_qml="$wheel_root/qml"

      [ -d "$wheel_lib" ] && export LD_LIBRARY_PATH="$wheel_lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

      if [ -d "$wheel_plugins" ]; then
        export QT_PLUGIN_PATH="$wheel_plugins"
        [ -d "$wheel_plugins/platforms" ] && export QT_QPA_PLATFORM_PLUGIN_PATH="$wheel_plugins/platforms"
      else
        unset QT_PLUGIN_PATH
        unset QT_QPA_PLATFORM_PLUGIN_PATH
      fi

      if [ -d "$wheel_qml" ]; then
        export QML2_IMPORT_PATH="$wheel_qml"
      else
        unset QML2_IMPORT_PATH
      fi
    else
      unset QT_PLUGIN_PATH
      unset QT_QPA_PLATFORM_PLUGIN_PATH
      unset QML2_IMPORT_PATH
    fi
  '';
in {
  devShells = {
    py_light = pkgs.mkShell {
      packages = with pkgs; [python312 uv pre-commit];
      shellHook = ''
        echo "🐍 py_light active (python + uv, no compilers)"
        ${python_consistency_hook}
      '';
    };

    py_build = pkgs.mkShell {
      packages = with pkgs; [python312 uv gcc gfortran cmake pkg-config openblas];
      shellHook = ''
        echo "🛠️  py_build active (gcc/gfortran/cmake/pkg-config/openblas)"
        echo "Use this shell for 'uv sync' when C/Fortran extensions are built."
        ${python_consistency_hook}
      '';
    };

    # VTK/Qt/GL shell tuned for wheels (PySide6 + VTK) on NixOS
    py_vtk = pkgs.mkShell {
      packages = with pkgs; [
        python312
        uv
        vtk
        qt6.qtbase
        qt6.qtwayland
        qt6.qtdeclarative
        qt6.qtimageformats
        qt6.qtsvg
        mesa
        libglvnd
        wayland
        libxkbcommon
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
        xorg.xcbutilcursor
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
        mesa-demos
        patchelf
      ];
      shellHook = ''
        ${python_consistency_hook}
        ${qt_wheel_shell_hook lib pkgs}
      '';
    };

    # Combined: build toolchain + VTK/Qt wheel runtime
    py_build_vtk = pkgs.mkShell {
      packages = with pkgs; [
        python312
        uv
        gcc
        gfortran
        cmake
        pkg-config
        openblas
        vtk
        qt6.qtbase
        qt6.qtwayland
        qt6.qtdeclarative
        qt6.qtimageformats
        qt6.qtsvg
        mesa
        libglvnd
        wayland
        libxkbcommon
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
        xorg.xcbutilcursor
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
        mesa-demos
        patchelf
      ];
      shellHook = ''
        echo "🛠️🖼️  py_build_vtk active (build toolchain + Qt/VTK wheels)"
        ${python_consistency_hook}
        ${qt_wheel_shell_hook lib pkgs}
      '';
    };
  };
}

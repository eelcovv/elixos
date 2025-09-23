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
        export QT_QPA_PLATFORM="xcb"
        export QT_XCB_GL_INTEGRATION="glx"
        export MPLBACKEND="${MPLBACKEND:-Agg}"
        # Optional for debugging:
        # export QT_DEBUG_PLUGINS=1

        # ---- Helper: prepend to LD_LIBRARY_PATH --------------------------------
        prepend() { export LD_LIBRARY_PATH="$1''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"; }

        # ---- Compat shims manylinux wheels expect -------------------------------
        COMPAT_DIR="$PWD/.nix-ld-compat"
        mkdir -p "$COMPAT_DIR"
        ln -sf "${lib.getLib pkgs.e2fsprogs}/lib/libcom_err.so.3" "$COMPAT_DIR/libcom_err.so.2"
        prepend "$COMPAT_DIR"

        # ---- Core GL + base libs (keep generic system libs; avoid system Qt) ----
        prepend "${lib.getLib pkgs.libglvnd}/lib"
        prepend "${lib.getLib pkgs.zlib}/lib"
        prepend "${lib.getLib pkgs.e2fsprogs}/lib"
        prepend "${lib.getLib pkgs.expat}/lib"
        prepend "${lib.getLib pkgs.gmp}/lib"
        prepend "${lib.getLib pkgs.p11-kit}/lib"
        prepend "${lib.getLib pkgs.zstd}/lib"
        prepend "${lib.getLib pkgs.dbus}/lib"

        # ---- X11 / xcb libs (incl. xcb-cursor) ----------------------------------
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

        # ---- Text / fonts / wayland / crypto / ICU ------------------------------
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

        # ---- Vendor GL driver paths on NixOS ------------------------------------
        [ -d /run/opengl-driver/lib ]     && prepend "/run/opengl-driver/lib"
        [ -d /run/opengl-driver-32/lib ]  && prepend "/run/opengl-driver-32/lib"

        # ---- HARD RULE: use only the wheel's Qt (PySide6) -----------------------
        # Stop Qt from scanning default plugin locations (prevents system Qt mixing)
        export QT_NO_PLUGIN_LOOKUP=1

        if [ -n "$VIRTUAL_ENV" ]; then
          pyver="$(python -c 'import sys;print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
          wheel_root="$VIRTUAL_ENV/lib/python${pyver:-3.12}/site-packages/PySide6/Qt"
          wheel_lib="$wheel_root/lib"
          wheel_plugins="$wheel_root/plugins"
          wheel_qml="$wheel_root/qml"

          # 1) Wheel Qt libraries FIRST on LD_LIBRARY_PATH (before any system Qt)
          if [ -d "$wheel_lib" ]; then
            # Put wheel lib at absolute front by rebuilding LD_LIBRARY_PATH
            export LD_LIBRARY_PATH="$wheel_lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          fi

          # 2) Force platform plugin path to the wheel only (no system fallback)
          if [ -d "$wheel_plugins" ]; then
            export QT_PLUGIN_PATH="$wheel_plugins"
            if [ -d "$wheel_plugins/platforms" ]; then
              export QT_QPA_PLATFORM_PLUGIN_PATH="$wheel_plugins/platforms"
            fi
          else
            unset QT_PLUGIN_PATH
            unset QT_QPA_PLATFORM_PLUGIN_PATH
          fi

          # 3) QML from wheel only
          if [ -d "$wheel_qml" ]; then
            export QML2_IMPORT_PATH="$wheel_qml"
          else
            unset QML2_IMPORT_PATH
          fi
        else
          # No venv: DO NOT point to system Qt plugins to avoid version skew
          unset QT_PLUGIN_PATH
          unset QT_QPA_PLATFORM_PLUGIN_PATH
          unset QML2_IMPORT_PATH
        fi

        echo "Try: glxinfo -B"
      '';
    };
  };
}

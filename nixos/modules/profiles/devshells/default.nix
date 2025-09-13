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
    # nixos/modules/profiles/devshells/default.nix (py_vtk excerpt)
    py_vtk = pkgs.mkShell {
      packages = with pkgs; [
        python312
        uv

        vtk
        # Keep Qt6 for your PySide6 app:
        qt6.qtbase
        qt6.qtwayland

        mesa
        libglvnd
        wayland
        libxkbcommon

        # X11 stack (extended)
        xorg.libX11
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXi
        xorg.libXrender # <-- important for your current error
        xorg.libXt # common VTK dep
        xorg.libXmu # common VTK dep
        xorg.libSM # session management
        xorg.libICE # ICE library
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

        # Runtime codecs/fonts/etc.
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

        # Diagnostics
        mesa-demos
        patchelf
      ];

      shellHook = ''
        echo "🖼️  py_vtk active (Qt/VTK/OpenGL on NixOS)"
        export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-wayland;xcb}"

        # Compat symlink for wheels expecting libcom_err.so.2
        COMPAT_DIR="$PWD/.nix-ld-compat"
        mkdir -p "$COMPAT_DIR"
        ln -sf "${lib.getLib pkgs.e2fsprogs}/lib/libcom_err.so.3" "$COMPAT_DIR/libcom_err.so.2"

        # Loader search paths (most specific first)
        prepend() { export LD_LIBRARY_PATH="$1''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"; }

        prepend "$COMPAT_DIR"
        prepend "${lib.getLib pkgs.libglvnd}/lib"   # libGL.so.1
        prepend "${lib.getLib pkgs.zlib}/lib"       # libz.so.1
        prepend "${lib.getLib pkgs.e2fsprogs}/lib"  # libcom_err.so.3
        prepend "${lib.getLib pkgs.expat}/lib"      # libexpat.so.1
        prepend "${lib.getLib pkgs.gmp}/lib"        # libgmp.so.10
        prepend "${lib.getLib pkgs.p11-kit}/lib"    # libp11-kit.so.0

        # X11 libs (cover libXrender + common VTK deps)
        prepend "${lib.getLib pkgs.xorg.libXrender}/lib"
        prepend "${lib.getLib pkgs.xorg.libX11}/lib"
        prepend "${lib.getLib pkgs.xorg.libXext}/lib"
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

        prepend "${lib.getLib pkgs.fontconfig}/lib"   # libfontconfig.so.1 (PySide6/Qt6 needs this)
        prepend "${lib.getLib pkgs.freetype}/lib"     # libfreetype.so.6
        prepend "${lib.getLib pkgs.harfbuzz}/lib"     # libharfbuzz.so.0
        prepend "${lib.getLib pkgs.libpng}/lib"       # libpng16.so.16 (often pulled via Qt)
        prepend "${lib.getLib pkgs.libjpeg}/lib"      # libjpeg.so.8
        prepend "${lib.getLib pkgs.libtiff}/lib"      # libtiff.so.6
        prepend "${lib.getLib pkgs.glib}/lib"          # libglib-2.0.so.0, libgobject-2.0.so.0, etc.
        prepend "${lib.getLib pkgs.pcre2}/lib"         # libpcre2-8.so.0 (glib dependency)
        prepend "${lib.getLib pkgs.libxkbcommon}/lib"  # libxkbcommon.so.0 (Qt input stack)
        prepend "${lib.getLib pkgs.wayland}/lib"       # libwayland-client.so.0, etc.
        prepend "${lib.getLib pkgs.openssl}/lib"       # libssl.so.3, libcrypto.so.3 (QtNetwork often needs)
        prepend "${lib.getLib pkgs.icu}/lib"           # ICU (Qt text shaping / locales if needed)

        prepend "${lib.getLib pkgs.zstd}/lib"   # provides libzstd.so.1
        prepend "${lib.getLib pkgs.dbus}/lib"   # provides libdbus-1.so.3


        # Vendor OpenGL driver paths (NixOS provides these)
        [ -d /run/opengl-driver/lib ]     && prepend "/run/opengl-driver/lib"
        [ -d /run/opengl-driver-32/lib ]  && prepend "/run/opengl-driver-32/lib"

        echo "Try: glxinfo -B"
      '';
    };
  };
}

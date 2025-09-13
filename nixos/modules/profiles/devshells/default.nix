# nixos/modules/profiles/devshells/default.nix
{
  pkgs,
  inputs,
  system ? builtins.currentSystem,
  lib ? pkgs.lib,
  ...
}: let
  # Resolve nixGL packages for the current system
  nixGL =
    if builtins.hasAttr system inputs.nixgl.packages
    then inputs.nixgl.packages.${system}
    else inputs.nixgl.packages.${pkgs.system};
in {
  # Expose an attribute set with multiple developer shells
  devShells = {
    # Lightweight Python shell: interpreter + uv + basic tools
    py_light = pkgs.mkShell {
      packages = with pkgs; [
        python312
        uv
        pre-commit
      ];
      shellHook = ''
        echo "🐍 py_light active (python + uv, no compilers)"
      '';
    };

    # Build-capable Python shell: add toolchain for packages needing local compilation
    py_build = pkgs.mkShell {
      packages = with pkgs; [
        python312
        uv
        gcc
        gfortran
        cmake
        pkg-config
        openblas
      ];
      shellHook = ''
        echo "🛠️  py_build active (gcc/gfortran/cmake/pkg-config/openblas)"
        echo "Use this shell for 'uv sync' when C/Fortran extensions are built."
      '';
    };

    # VTK/Qt/OpenGL GUI shell with nixGL wrappers for proper GPU driver binding
    py_vtk = pkgs.mkShell {
      packages = with pkgs; [
        python312
        uv

        # Qt/GL runtime bits and common X11/Wayland deps for Qt xcb
        vtk
        qt6.qtbase
        qt6.qtwayland
        mesa
        libglvnd
        wayland
        libxkbcommon
        xorg.libX11
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXi
        xorg.libXrender
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

        # Text/codec stack frequently needed by GUI apps
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

        # nixGL wrappers for vendor driver dispatch
        nixGL.nixGLNvidia
        nixGL.nixGLIntel
        nixGL.nixVulkanNvidia
      ];

      # Important: do NOT set LD_LIBRARY_PATH here; rely on nixGL wrappers instead.
      shellHook = ''
        echo "🖼️  py_vtk active (Qt/VTK/OpenGL + nixGL wrappers)"
        echo "     Run GUI/GL apps via: nixGLNvidia pymeshup"
        echo "     or:                  nixGLNvidia python -c 'import vtk; print(vtk.vtkVersion().GetVTKVersion())'"

        # Allow Qt to try Wayland first and fall back to XCB when needed
        export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-wayland;xcb}"
      '';
    };
  };
}

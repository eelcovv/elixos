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
    py_vtk = pkgs.mkShell {
      packages = with pkgs;
        [
          python312
          uv
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
        ]
        # Only add nixGL wrappers when safe to evaluate on this Nix
        ++ nixGLWrappers;

      shellHook = ''
        echo "🖼️  py_vtk active (Qt/VTK/OpenGL)"
        echo "     Use nixGL wrappers for GUI/GL apps (NVIDIA/Intel)."
        export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-wayland;xcb}"

        # Fallback shims: if nixGL wrappers are not on PATH (e.g. older Nix), run via nix run.
        if ! command -v nixGLNvidia >/dev/null 2>&1; then
          nixGLNvidia() { nix run github:guibou/nixGL#nixGLNvidia -- "$@"; }
        fi
        if ! command -v nixGLIntel >/dev/null 2>&1; then
          nixGLIntel() { nix run github:guibou/nixGL#nixGLIntel -- "$@"; }
        fi

        echo "     Example: nixGLNvidia python -c 'import vtk; print(vtk.vtkVersion().GetVTKVersion())'"
      '';
    };
  };
}

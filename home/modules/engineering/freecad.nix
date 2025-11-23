{
  pkgs,
  lib,
  ...
}: let
  # Create a Python virtual environment using 'uv' and install capytaine into it.
  # This derivation requires network access, so we must provide a fixed output hash.
  # Nix will provide the correct hash in the error message on the first build attempt.
  capytaineEnv = pkgs.stdenv.mkDerivation {
    name = "capytaine-uv-env";
    # uv is needed to build the environment
    nativeBuildInputs = [pkgs.uv];

    # This is a fixed-output derivation, which allows network access during the build.
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    # IMPORTANT: Replace this with the actual hash Nix provides on the first build failure.
    outputHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

    # The build script creates a venv in $out and uses uv to install capytaine.
    buildCommand = ''
      set -e
      # Prevent uv from writing to its cache in the sandbox's home by setting a temporary home directory.
      export HOME=$(mktemp -d)
      # Create a virtual environment in the output directory.
      uv venv $out --python ${pkgs.python3}/bin/python
      # Install capytaine into that environment.
      uv pip install capytaine --python $out/bin/python
      # As a sanity check, list installed packages
      uv pip list --python $out/bin/python > $out/installed-packages.txt
    '';
  };

  # Create a wrapper around the freecad-wayland executable.
  # This makes the Python packages from our 'uv' environment available to FreeCAD.
  freecadWithWorkbenchDeps = pkgs.symlinkJoin {
    name = "freecad-wayland-with-deps";
    paths = [pkgs.freecad-wayland];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/freecad --prefix PYTHONPATH : "${capytaineEnv}/lib/python${lib.versions.majorMinor pkgs.python3.version}/site-packages"
    '';
  };
in {
  # Installs FreeCAD with its workbenches and required Python dependencies.

  # Install our newly wrapped FreeCAD package.
  home.packages = [freecadWithWorkbenchDeps];

  # We fetch the source code of the workbenches from their GitHub repositories.
  # This is then placed in the correct directory where FreeCAD can find them.
  home.file.".local/share/FreeCAD/Mod/Ship" = {
    source = pkgs.fetchFromGitHub {
      owner = "FreeCAD";
      # IMPORTANT: Replace this placeholder with the correct hash that Nix provides on the first build.
      sha256 = "sha256-dt21MZgwpdqVfdGonZctS+T8xRaYI1E9Dz7m+J0Guhk=";
    };
    recursive = true;
  };

  home.file.".local/share/FreeCAD/Mod/CurvedShapes" = {
    source = pkgs.fetchFromGitHub {
      owner = "chbergmann";
      repo = "CurvedShapesWorkbench";
      # For reproducibility, it's better to use a specific commit hash instead of "master".
      rev = "master";
      # IMPORTANT: Replace this placeholder with the correct hash that Nix provides on the first build.
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    recursive = true;
  };
}

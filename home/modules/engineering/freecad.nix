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
    outputHash = lib.fakeSha256; # Placeholder, Nix will tell you the real one.

    # The build script creates a venv in $out and uses uv to install capytaine.
    buildCommand = ''
      set -e
      # Create a virtual environment in the output directory
      uv venv $out
      # Install capytaine into that environment
      $out/bin/uv pip install capytaine
      # As a sanity check, list installed packages
      $out/bin/uv pip list > $out/installed-packages.txt
    '';
  };

  # Create a wrapper around the freecad-wayland executable.
  # This makes the Python packages from our 'uv' environment available to FreeCAD.
  freecadWithWorkbenchDeps = pkgs.symlinkJoin {
    name = "freecad-wayland-with-deps";
    paths = [pkgs.freecad-wayland];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/freecad --prefix PYTHONPATH : "${capytaineEnv}/${pkgs.python3.sitePackages}"
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
      repo = "freecad.ship";
      # For reproducibility, it's better to use a specific commit hash instead of "master".
      rev = "master";
      # Replace this placeholder with the correct hash that Nix provides on the first build.
      hash = lib.fakeSha256;
    };
    recursive = true;
  };

  #home.file.".local/share/FreeCAD/Mod/CurvedShapes" = {
  #  source = pkgs.fetchFromGitHub {
  #    owner = "chbergmann";
  #    repo = "CurvedShapesWorkbench";
  ##    # For reproducibility, it's better to use a specific commit hash instead of "master".
  #    rev = "master";
  #    # Replace this placeholder with the correct hash that Nix provides on the first build.
  #    hash = lib.fakeSha256;
  #  };
  #  recursive = true;
  #};
}

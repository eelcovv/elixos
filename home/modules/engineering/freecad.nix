{
  pkgs,
  lib,
  ...
}: let
  # Package definition for capytaine, fetched from PyPI.
  # This is the idiomatic Nix way to handle Python dependencies.
  capytaine = pkgs.python3Packages.buildPythonPackage rec {
    pname = "capytaine";
    version = "2.3.1"; # Latest version as of late 2025.
    format = "pyproject";

    src = pkgs.fetchPypi {
      inherit pname version;
      # IMPORTANT: This is a placeholder hash. The build will fail on the first run,
      # and Nix will output the correct hash. You need to replace this value
      # with the hash provided in the error message.
      sha256 = "sha256-N17CmS2Cs32zP23iCfs7uRkEvMTArzRkKMiqK1x5aKA=";
    };

    # Dependencies for capytaine, found on its PyPI page.
    nativeBuildInputs = with pkgs.python3Packages; [
      meson-python
      oldest-supported-numpy
      charset-normalizer
      pkgs.gfortran
    ];
    propagatedBuildInputs = with pkgs.python3Packages; [
      numpy
      scipy
      pandas
      xarray
      matplotlib
      meshio
    ];

    postPatch = ''
      # The pyproject.toml file specifies that the version is dynamic, which
      # causes the build system to run a script that fails in the Nix sandbox.
      # We patch the file to insert the version statically, avoiding the script execution.
      substituteInPlace pyproject.toml \
        --replace 'dynamic = ["version"]' 'version = "${version}"'
    '';
  };

  # Create a Python environment that includes the capytaine package.
  pythonWithCapytaine = pkgs.python3.withPackages (ps: [capytaine]);

  # Since freecad-wayland does not have a `withPackages` function, we wrap it
  # to include our Python environment.
  freecadWithDeps = pkgs.symlinkJoin {
    name = "freecad-wayland-with-deps";
    paths = [pkgs.freecad-wayland];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/FreeCAD \
        --prefix PYTHONPATH ":" "${pythonWithCapytaine}/${pkgs.python3.sitePackages}"
    '';
  };
in {
  # Installs FreeCAD with its workbenches and required Python dependencies.

  # Install FreeCAD with the added Python packages.
  home.packages = [freecadWithDeps];

  # We fetch the source code of the workbenches from their GitHub repositories.
  # This is then placed in the correct directory where FreeCAD can find them.
  home.file.".local/share/FreeCAD/Mod/Ship_master" = {
    source = pkgs.fetchFromGitHub {
      owner = "FreeCAD";
      repo = "freecad.ship";
      rev = "master";
      # You might need to update this hash if the master branch changes.
      sha256 = "sha256-dt21MZgwpdqVfdGonZctS+T8xRaYI1E9Dz7m+J0Guhk=";
    };
    recursive = true;
  };

  home.file.".local/share/FreeCAD/Mod/CurvedShapes" = {
    source = pkgs.fetchFromGitHub {
      owner = "chbergmann";
      repo = "CurvedShapesWorkbench";
      rev = "master";
      # You might need to update this hash if the master branch changes.
      sha256 = "sha256-dt21MZgwpdqVfdGonZctS+T8xRaYI1E9Dz7m+J0Guhk=";
    };
    recursive = true;
  };
}

{
  pkgs,
  lib,
  ...
}: let
  # Create a Python environment that includes the capytaine package from our overlay.
  pythonWithCapytaine = pkgs.python3.withPackages (ps: [
    ps.capytaine
  ]);

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
  home.file.".local/share/FreeCAD/Mod/Ship" = {
    source = (pkgs.fetchFromGitHub {
      owner = "FreeCAD";
      repo = "freecad.ship";
      rev = "master";
      # You might need to update this hash if the master branch changes.
      sha256 = "sha256-ekkY7DAzwOAf0pPA8IcVC2iUi8b3JZ3QZ+TmHGzdvrs=";
    }) + "/freecad/ship";
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

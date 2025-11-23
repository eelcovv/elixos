{
  pkgs,
  lib,
  ...
}:
let
  # Create a Python environment containing the 'capytaine' library required by the Ship workbench.
  pythonWithCapytaine = pkgs.python3.withPackages (ps: [
    ps.capytaine
  ]);

  # Create a wrapper around the freecad-wayland executable.
  # This wrapper modifies the PYTHONPATH environment variable when FreeCAD starts,
  # making our custom Python environment (with capytaine) available to it.
  freecadWithWorkbenchDeps = pkgs.symlinkJoin {
    name = "freecad-wayland-with-deps";
    paths = [ pkgs.freecad-wayland ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/freecad --prefix PYTHONPATH : "${pythonWithCapytaine}/${pkgs.python3.sitePackages}"
    '';
  };
in
{
  # Installs FreeCAD with its workbenches and required Python dependencies.

  # Install our newly wrapped FreeCAD package.
  home.packages = [ freecadWithWorkbenchDeps ];

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

  home.file.".local/share/FreeCAD/Mod/CurvedShapes" = {
    source = pkgs.fetchFromGitHub {
      owner = "chbergmann";
      repo = "CurvedShapesWorkbench";
      # For reproducibility, it's better to use a specific commit hash instead of "master".
      rev = "master";
      # Replace this placeholder with the correct hash that Nix provides on the first build.
      hash = lib.fakeSha256;
    };
    recursive = true;
  };
}

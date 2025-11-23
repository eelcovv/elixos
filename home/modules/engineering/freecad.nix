{
  pkgs,
  lib,
  ...
}: {
  # Installs FreeCAD with its workbenches and required Python dependencies.

  # The 'ship' workbench requires the 'capytaine' python library.
  # We use `withPackages` to add it to FreeCAD's Python environment.
  home.packages = with pkgs; [
    (freecad-wayland.withPackages
      (ps: [
        ps.capytaine
      ]))
  ];

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

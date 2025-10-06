{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./openfoam.nix
    # ./paraview.nix
    # ./paraview-container.nix
    ./paraview-flatpak.nix
  ];

  # GUI/engineering tools that you want locally
  home.packages = with pkgs; [
    blender
    meshlab
    gmsh
    gnuplot
    freecad-wayland
    gsettings-desktop-schemas
    hicolor-icon-theme
  ];

  # Zet opties direct onder 'engineering.*' (geen extra 'engineering = { ... }' blok)
  engineering.paraviewFlatpak.enable = true;

  engineering.openfoam = {
    enable = true;
    engine = "docker"; # of "podman"
    image = "docker.io/opencfd/openfoam-default";
    tag = "2406";
  };
}

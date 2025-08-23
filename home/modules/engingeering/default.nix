# home/modules/engineering/default.nix
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./openfoam.nix
  ];

  # GUI/engineering tools that you want locally
  home.packages = with pkgs; [
    blender
    freecad-wayland
    gsettings-desktop-schemas
    hicolor-icon-theme
    paraview
  ];

  # Enable OpenFOAM helpers; pick the tag you prefer (2312, 2406, 2412, ...)
  engineering.openfoam.enable = true;
  engineering.openfoam.tag = "2406"; # optional override (default is 2406)
  # engineering.openfoam.image = "docker.io/opencfd/openfoam-default"; # default
}

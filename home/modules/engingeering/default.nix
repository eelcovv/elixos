{pkgs, ...}: {
  home.packages = with pkgs; [
    blender
    freecad-wayland
    openfoam
    paraview
  ];
}

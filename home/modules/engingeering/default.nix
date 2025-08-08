{pkgs, ...}: {
  home.packages = with pkgs; [
    freecad-wayland
    blender
    paraview
  ];
}

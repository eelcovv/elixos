{pkgs, ...}: {
  home.packages = with pkgs; [
    blender
    freecad-wayland
    paraview
  ];
}

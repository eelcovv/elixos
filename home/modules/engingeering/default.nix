# home/modules/engineering/default.nix
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
    freecad-wayland
    gsettings-desktop-schemas
    hicolor-icon-theme
  ];

  engineering = {
    #paraview = {
    #  enable = true;
    #  host.enable = true;
    #  host.installPackage = true;
    #  host.installPvClean = true;
    #  container.enable = false; # zet op true als je container wilt
    #  container.image = "local/paraview:24.04";
    #  container.runtime = "podman";
    #};

    paraviewFlatpak.enable = true;

    # Enable OpenFOAM helpers; pick the tag you prefer (2312, 2406, 2412, ...)
    openfoam = {
      enable = true;
      tag = "2406"; # optional override (default is 2406)
      # image = "docker.io/opencfd/openfoam-default"; # default
    };
  };
}

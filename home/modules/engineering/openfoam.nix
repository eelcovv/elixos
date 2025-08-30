{
  config,
  pkgs,
  ...
}: let
  # pad naar je scripts-map
  scripts = ./scripts/openfoam;
in {
  # tools in PATH
  home.packages = [
    pkgs.coreutils
    pkgs.bashInteractive
    pkgs.docker # of pkgs.podman, als je ooit wilt wisselen
  ];

  # optioneel: engine/image/tag als env voor de scripts
  home.sessionVariables = {
    OPENFOAM_ENGINE = "docker"; # of "podman"
    OPENFOAM_IMAGE = "docker.io/opencfd/openfoam-default";
    OPENFOAM_TAG = "2406";
  };

  # Symlink de scripts naar ~/.local/bin
  home.file.".local/bin/of-shell".source = scripts + "/of-shell";
  home.file.".local/bin/of-shell-root".source = scripts + "/of-shell-root";
  home.file.".local/bin/of-run".source = scripts + "/of-run";
  home.file.".local/bin/of-fix-perms".source = scripts + "/of-fix-perms";
  home.file.".local/bin/mkfoam".source = scripts + "/mkfoam";
}

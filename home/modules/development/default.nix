{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./docker.nix
    ./direnv.nix
    ./git-default.nix
    ./pycharm.nix
    ./python.nix
    ./python-devtools.nix
    ./uv.nix
    ./vscode.nix
    ./rootless-podman-storage.nix
  ];

  home.packages = with pkgs; [
    alejandra
    htop
    wget
    tree
    direnv
    gnumake
  ];
}

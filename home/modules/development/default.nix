{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./git-default.nix
    ./pycharm.nix
    ./vscode.nix
  ];

  home.packages = with pkgs; [
    alejandra
    htop
    wget
    tree
    direnv
  ];
}

{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./devel/git-default.nix
    ./devel/pycharm.nix
    ./devel/vscode.nix
  ];

  home.packages = with pkgs; [
    alejandra
    htop
    wget
    tree
    direnv
  ];
}

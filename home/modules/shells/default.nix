{
  config,
  pkgs,
  lib,
  ...
}: {
  # note that we import zsh via users
  imports = [
    ./bash.nix
    ./powershell.nix
    ./inputrc.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    alejandra
    htop
    wget
    tree
    direnv
  ];
}

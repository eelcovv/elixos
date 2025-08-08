{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./vim
    ./nvim
  ];
}

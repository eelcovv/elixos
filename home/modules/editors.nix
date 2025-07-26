{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./editors/vim
    ./editors/nvim
  ];
}

{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./browsers.nix
    ./remote-access.nix
  ];
}

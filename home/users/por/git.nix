{
  config,
  pkgs,
  lib,
  ...
}: (import ../../modules/development/git.nix {
  inherit config pkgs lib;
  userName = "Karnrawee Mangkang";
  userEmail = "karnrawee.mangkang@gmail.com";
})

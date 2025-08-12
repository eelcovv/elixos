{
  config,
  pkgs,
  lib,
  ...
}: (import ../../modules/development/git.nix {
  inherit config pkgs lib;
  userName = "Eelco van Vliet";
  userEmail = "eelcovv@gmail.com";
})

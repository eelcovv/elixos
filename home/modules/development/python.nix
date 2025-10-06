# home/modules/development/python.nix
{
  pkgs,
  lib,
  ...
}: let
  # Pick a single default interpreter for daily use
  py = pkgs.python312;
in {
  # Keep Python globally available (lightweight); compilers/libs live in devShells
  home.packages = [py];

  # If you occasionally need another version, use:
  #   nix shell nixpkgs#python311 -c python
  # or enter a project devShell that pins a different interpreter.
}

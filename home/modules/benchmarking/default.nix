{ lib, ... }:

let
  files = builtins.filter (file:
    lib.hasSuffix ".nix" file && file != "default.nix"
  ) (builtins.attrNames (builtins.readDir ./.));
in
builtins.map (file: import ./${file}) files


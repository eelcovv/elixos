# pkgs/overlay.nix
#
# This overlay adds our custom packages to the nixpkgs set.
final: prev: {
  # Add your custom packages here
  capytaine = final.callPackage ./capytaine { };
}

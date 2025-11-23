# pkgs/overlay.nix
#
# This overlay adds our custom packages to the nixpkgs set.
final: prev: {
  python3Packages = prev.python3Packages.override (pyfinal: pyprev: {
    capytaine = final.callPackage ./capytaine { };
  });
}

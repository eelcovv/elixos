# pkgs/overlay.nix
#
# This overlay adds our custom packages to the nixpkgs set.
final: prev: {
  # Add python packages to the python3Packages package set
  python3Packages = prev.python3Packages.override {
    overrides = final.lib.composeExtensions (prev.python3Packages.overrides or (_: _: {})) (
      python-final: python-prev: {
        capytaine = final.callPackage ./capytaine { };
      }
    );
  };
}

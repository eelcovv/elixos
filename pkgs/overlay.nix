# pkgs/overlay.nix
#
# This overlay adds our custom packages to the nixpkgs set.
final: prev: {
  python3 = prev.python3.override {
    packageOverrides = pyfinal: pyprev: {
      # We use final.callPackage to get access to non-python dependencies like gfortran.
      # However, this means we must explicitly pass ALL python-specific dependencies
      # that are not in the top-level 'final' set. We take these from 'pyfinal'.
      capytaine = final.callPackage ./capytaine {
        inherit (pyfinal)
          # Build-time dependencies
          buildPythonPackage
          meson-python
          oldest-supported-numpy
          charset-normalizer
          # Runtime dependencies
          numpy
          scipy
          pandas
          xarray
          matplotlib
          meshio;
      };
    };
  };
}

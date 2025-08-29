# home/modules/python.nix
{
  pkgs,
  lib,
  ...
}: let
  # Keep exactly one "full" interpreter for headers/pkgconfig/etc.
  pyFull = pkgs.python312Full;

  # Bundle other Python versions but link only their /bin, then prune unversioned tools.
  otherPyBins = pkgs.buildEnv {
    name = "python-multi-bins";
    paths =
      [
        pkgs.python310
        pkgs.python311
        # intentionally skip 3.12 here; we expose python312Full separately
      ]
      ++ lib.optional (pkgs ? python313) pkgs.python313
      ++ lib.optional (pkgs ? python314) pkgs.python314;

    # Only expose /bin from the above interpreters → no lib/include/pkgconfig collisions.
    pathsToLink = ["/bin"];

    # If two packages still drop the same filename under /bin, allow it temporarily;
    # we will prune duplicates below.
    ignoreCollisions = true;

    # Prune unversioned helpers to avoid /bin name clashes with the full Python.
    # Keep only python3.X and pip3.X; drop idle3, pydoc3, 2to3, python3, pip3, etc.
    postBuild = ''
      set -eu
      if [ -d "$out/bin" ]; then
        for f in "$out/bin/"*; do
          bn="$(basename "$f")"
          case "$bn" in
            python3.*|pip3.*)
              # keep versioned
              ;;
            *)
              rm -f "$f"
              ;;
          esac
        done
      fi
    '';
  };
in {
  home.packages = [
    pyFull
    otherPyBins
  ];
}

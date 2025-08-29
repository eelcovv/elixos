# home/modules/python.nix
{
  pkgs,
  lib,
  ...
}: let
  # One "full" interpreter for headers, pkgconfig, etc.
  pyFull = pkgs.python312Full;

  # Other interpreters: bins only (avoid lib/include/pkgconfig collisions)
  otherPyBins = pkgs.buildEnv {
    name = "python-multi-bins";
    paths =
      [
        pkgs.python310
        pkgs.python311
        # Skip 3.12 here (we already have python312Full separately)
      ]
      ++ (
        if pkgs ? python313
        then [pkgs.python313]
        else []
      )
      ++ (
        if pkgs ? python314
        then [pkgs.python314]
        else []
      );
    pathsToLink = ["/bin"];
    # In case two packages provide same binary name (rare), allow it.
    # Usually unnecessary, but harmless here.
    ignoreCollisions = true;
  };
in {
  # Result: one full Python (3.12) + A bundle with only /bin of the rest
  home.packages = [
    pyFull
    otherPyBins
  ];
}

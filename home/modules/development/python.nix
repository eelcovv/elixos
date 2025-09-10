# home/modules/development/python.nix
{
  pkgs,
  lib,
  ...
}: let
  pyFull = pkgs.python312Full;

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

    pathsToLink = ["/bin"];
    ignoreCollisions = true;

    postBuild = ''
      set -eu
      if [ -d "$out/bin" ]; then
        for f in "$out/bin/"*; do
          bn="$(basename "$f")"
          case "$bn" in
            python3.*|pip3.*) ;;
            *) rm -f "$f" ;;
          esac
        done
      fi
    '';
  };
in {
  home.packages = [pyFull otherPyBins];
}

# home/modules/development/python-devtools.nix
{
  pkgs,
  lib,
  ...
}: let
  # Prefer top-level packages; fall back to python3Packages.* if needed.
  py = pkgs.python3Packages;

  # Helper to include a package only if it exists (non-null)
  opt = pkg: lib.optional (pkg != null) pkg;

  # Tool picks with graceful fallbacks per channel
  twine = pkgs.twine or (py.twine or null);
  poetry = pkgs.poetry or (py.poetry or null);
  tox = pkgs.tox or (py.tox or null);
  toxUv = pkgs.tox-uv or (py.tox-uv or null); # may not exist on older channels
  preCommit = pkgs.pre-commit or (py.pre-commit or null);
  ruff = pkgs.ruff or (py.ruff or null);
  mypy = pkgs.mypy or (py.mypy or null);
  deptry = pkgs.deptry or (py.deptry or null); # newer channels
  pytest = pkgs.pytest or (py.pytest or null);
  coverage = pkgs.coverage or (py.coveragepy or null);
  junit2html = pkgs.junit2html or (py.junit2html or null);
in {
  # Global Python dev toolbelt (interpreter-agnostic tools on PATH).
  # Project deps gaan in je uv-venvs.
  home.packages =
    [
      pkgs.uv
    ]
    ++ opt twine
    ++ opt poetry
    ++ opt tox
    ++ opt toxUv
    ++ opt preCommit
    ++ opt ruff
    ++ opt mypy
    ++ opt deptry
    ++ opt pytest
    ++ opt coverage
    ++ opt junit2html;
}

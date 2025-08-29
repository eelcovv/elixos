# home/modules/devtools.nix
{pkgs, ...}: {
  # Global developer toolbelt (interpreter-agnostic tools).
  # Keep project dependencies inside uv-managed environments.
  home.packages = with pkgs; [
    # Package/env management & publishing
    uv
    twine
    poetry

    # Test & multi-Python orchestration
    tox # classic tox
    tox-uv # optional: tox plugin to use uv for deps (if available)

    # Quality / static analysis
    pre-commit
    ruff
    mypy
    deptry

    # Test runner & reporting (optional globally; often run via `uv run`)
    pytest
    coverage
    junit2html

    # Build helpers (optional, handy for wheels)
    python3Packages.build
    python3Packages.wheel
    # Cython often lives in envs, but add globally if you compile a lot:
    # python3Packages.cython
  ];
}

# home/modules/uv.nix
{pkgs, ...}: let
  uvWrappers = [
    (pkgs.writeShellScriptBin "uv-system" ''
      # Always use only system interpreters (never download CPython).
      set -euo pipefail
      export UV_PYTHON_PREFERENCE="${UV_PYTHON_PREFERENCE: -only-system}" # Nix interpolatie: OK (links)
      export UV_PYTHON_DOWNLOADS="${UV_PYTHON_DOWNLOADS: -never}"         # Nix interpolatie: OK (links)
      # Maar de rechters zijn Bash vars en moeten letterlijk zijn:
      export UV_PYTHON_PREFERENCE="\${UV_PYTHON_PREFERENCE: -only-system}"
      export UV_PYTHON_DOWNLOADS="\${UV_PYTHON_DOWNLOADS: -never}"
      exec ${pkgs.uv}/bin/uv --system "$@"
    '')

    (pkgs.writeShellScriptBin "uv-py" ''
      # Pick a specific interpreter version by MAJOR.MINOR.
      # Usage: uv-py 3.12 run python -V
      set -euo pipefail
      if [ $# -lt 1 ]; then
        echo "Usage: uv-py <MAJOR.MINOR> [uv args...]" >&2
        echo "Example: uv-py 3.12 run pytest -q" >&2
        exit 2
      fi
      ver="$1"; shift
      py_path="$(command -v "python\${ver}" || true)"
      if [ -z "$py_path" ]; then
        echo "python\${ver} not found on PATH (install it via Home-Manager)" >&2
        exit 1
      fi
      export UV_PYTHON_PREFERENCE="\${UV_PYTHON_PREFERENCE: -only-system}"
      export UV_PYTHON_DOWNLOADS="\${UV_PYTHON_DOWNLOADS: -never}"
      export UV_PYTHON="$py_path"
      exec ${pkgs.uv}/bin/uv --system "$@"
    '')

    (pkgs.writeShellScriptBin "uv-python-list" ''
      # Show what uv detects as system interpreters.
      set -euo pipefail
      export UV_PYTHON_PREFERENCE="\${UV_PYTHON_PREFERENCE: -only-system}"
      export UV_PYTHON_DOWNLOADS="\${UV_PYTHON_DOWNLOADS: -never}"
      exec ${pkgs.uv}/bin/uv --system python list
    '')

    (pkgs.writeShellScriptBin "uv-venv" ''
      # Create a venv with a given MAJOR.MINOR version easily.
      # Usage: uv-venv 3.12 .venv-312
      set -euo pipefail
      if [ $# -lt 2 ]; then
        echo "Usage: uv-venv <MAJOR.MINOR> <path>" >&2
        echo "Example: uv-venv 3.11 .venv-311" >&2
        exit 2
      fi
      ver="$1"; shift
      dst="$1"; shift
      py_path="$(command -v "python\${ver}" || true)"
      if [ -z "$py_path" ]; then
        echo "python\${ver} not found on PATH (install it via Home-Manager)" >&2
        exit 1
      fi
      export UV_PYTHON_PREFERENCE="\${UV_PYTHON_PREFERENCE: -only-system}"
      export UV_PYTHON_DOWNLOADS="\${UV_PYTHON_DOWNLOADS: -never}"
      export UV_PYTHON="$py_path"
      exec ${pkgs.uv}/bin/uv --system venv "$dst" "$@"
    '')
  ];
in {
  home.packages = [pkgs.uv] ++ uvWrappers;

  # Guard so uv never downloads interpreters on NixOS.
  home.sessionVariables = {
    UV_PYTHON_PREFERENCE = "only-system";
    UV_PYTHON_DOWNLOADS = "never";
  };
}

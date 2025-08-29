# home/modules/development/uv.nix
{pkgs, ...}: let
  uvWrappers = [
    (pkgs.writeShellScriptBin "uv-system" ''
      # Run uv; policy via env (sessionVariables)
      set -euo pipefail
      exec ${pkgs.uv}/bin/uv "$@"
    '')

    (pkgs.writeShellScriptBin "uv-python-list" ''
      # List interpreters uv can see
      set -euo pipefail
      exec ${pkgs.uv}/bin/uv python list
    '')

    (pkgs.writeShellScriptBin "uv-py" ''
      # Usage: uv-py 3.12 run python -V
      set -euo pipefail
      if [ $# -lt 1 ]; then
        echo "Usage: uv-py <MAJOR.MINOR> [uv args...]" >&2
        exit 2
      fi
      ver="$1"; shift
      py_path="$(command -v python$ver || true)"
      if [ -z "$py_path" ]; then
        echo "python$ver not found on PATH (install it via Home-Manager)" >&2
        exit 1
      fi
      export UV_PYTHON="$py_path"
      exec ${pkgs.uv}/bin/uv "$@"
    '')

    (pkgs.writeShellScriptBin "uv-venv" ''
      # Usage: uv-venv 3.12 .venv-312
      set -euo pipefail
      if [ $# -lt 2 ]; then
        echo "Usage: uv-venv <MAJOR.MINOR> <path>" >&2
        exit 2
      fi
      ver="$1"; shift
      dst="$1"; shift
      py_path="$(command -v python$ver || true)"
      if [ -z "$py_path" ]; then
        echo "python$ver not found on PATH (install it via Home-Manager)" >&2
        exit 1
      fi
      export UV_PYTHON="$py_path"
      exec ${pkgs.uv}/bin/uv venv "$dst" "$@"
    '')
  ];
in {
  home.packages = [pkgs.uv] ++ uvWrappers;

  # Centrale defaults: geen Bash default-expansies nodig in wrappers
  home.sessionVariables = {
    UV_PYTHON_PREFERENCE = "only-system";
    UV_PYTHON_DOWNLOADS = "never";
  };
}

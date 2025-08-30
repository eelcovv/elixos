#!/usr/bin/env bash
set -euo pipefail
engine="${OPENFOAM_ENGINE:-docker}"
image="${OPENFOAM_IMAGE:-docker.io/opencfd/openfoam-default}"
tag="${OPENFOAM_TAG:-2406}"

exec "${engine}" run --rm -it \
  --user 0:0 \
  -v "$PWD":/case -w /case \
  "${image}:${tag}" \
  bash -lc 'for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f "$p" ]; then source "$p" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo "[of-shell-root] cwd=$(pwd), uid=$(id -u), gid=$(id -g)"; exec bash -i'

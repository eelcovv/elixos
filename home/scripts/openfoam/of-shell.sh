#!/usr/bin/env bash
set -euo pipefail
uid=$(id -u)
gid=$(id -g)
engine="${OPENFOAM_ENGINE:-docker}"   # docker of podman
image="${OPENFOAM_IMAGE:-docker.io/opencfd/openfoam-default}"
tag="${OPENFOAM_TAG:-2406}"

exec "${engine}" run --rm -it \
  --user "${uid}:${gid}" \
  -v "$PWD":/case -w /case \
  "${image}:${tag}" \
  bash -lc 'for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f "$p" ]; then source "$p" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo "[of-shell] cwd=$(pwd), uid=$(id -u), gid=$(id -g)"; exec bash -i'

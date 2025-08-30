#!/usr/bin/env bash
set -euo pipefail
if [ $# -lt 1 ]; then
  echo "Usage: of-run <command> [args...]" >&2
  exit 2
fi
uid=$(id -u)
gid=$(id -g)
cmd="$*"
engine="${OPENFOAM_ENGINE:-docker}"
image="${OPENFOAM_IMAGE:-docker.io/opencfd/openfoam-default}"
tag="${OPENFOAM_TAG:-2406}"

exec "${engine}" run --rm \
  --user "${uid}:${gid}" \
  -v "$PWD":/case -w /case \
  "${image}:${tag}" \
  bash -lc 'for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f "$p" ]; then source "$p" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo "[of-run] '"$cmd"'"; eval '"$cmd"''

#!/usr/bin/env bash
# of-shell: Open an interactive shell with the OpenFOAM environment (Docker/Podman).
set -euo pipefail

ENGINE="${OPENFOAM_ENGINE:-docker}"                       # docker or podman
IMAGE="${OPENFOAM_IMAGE:-docker.io/opencfd/openfoam-default}"
TAG="${OPENFOAM_TAG:-2406}"

UIDGID_ARGS=()
if [ "${ENGINE}" = "docker" ] || [ "${ENGINE}" = "podman" ]; then
  UIDGID_ARGS=(--user "$(id -u)":"$(id -g)")
fi

TTY_OPTS=()
if [ -t 0 ] && [ -t 1 ]; then
  TTY_OPTS=(-it)
fi

# Mount the current directory and use it as workdir inside the container.
exec "${ENGINE}" run --rm "${TTY_OPTS[@]}" \
  "${UIDGID_ARGS[@]}" \
  -v "$PWD:$PWD" -w "$PWD" \
  "${IMAGE}:${TAG}" \
  / bash -i


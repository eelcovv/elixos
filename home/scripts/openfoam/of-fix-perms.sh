#!/usr/bin/env bash
# of-fix-perms: Fix file ownership/permissions in the current directory to the host user.
set -euo pipefail
uid=$(id -u)
gid=$(id -g)
echo "Chowning $(pwd) recursively to ${uid}:${gid} ..."
chmod -R u+rwX,g+rwX .
chown -R "${uid}:${gid}" .
echo "Done."


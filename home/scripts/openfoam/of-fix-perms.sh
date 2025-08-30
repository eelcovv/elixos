#!/usr/bin/env bash
set -euo pipefail
user_id=$(id -u)
group_id=$(id -g)
echo "Chowning $(pwd) recursively to ${user_id}:${group_id} ..."
chmod -R u+rwX,g+rwX .
chown -R "${user_id}:${group_id}" .
echo "Done."

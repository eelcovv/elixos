#!/usr/bin/env bash
set -euo pipefail
name="${1:-case}"
touch "${name}.foam"
echo "Created: ${name}.foam (open in ParaView)."

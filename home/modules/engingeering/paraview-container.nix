# Launch ParaView inside the image (or fallback to host pv-clean)
exec podman run --rm -it \
  --user 0:0 \
  "${mounts[@]}" "${extra_mounts[@]}" "${theme_mounts[@]}" \
  "${extra_env[@]}" \
  "$IMAGE" \
  bash -lc '
    # Source openfoam Env as present
    for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do
      if [ -f "$p" ]; then
        source "$p" >/dev/null 2>&1 || true
        break
      fi
    done
    cd /case || exit 1
    if command -v paraview >/dev/null 2>&1; then
      exec paraview
    else
      echo "[of-paraview] Paraview is missing in $ image-fall back on host (pv-clean)..." >&2
      exit 127
    fi
  '

# When we come here (exit 127), try Host Paraview
status=$?
if [ $status -eq 127 ]; then
  if command -v pv-clean >/dev/null 2>&1; then
    exec pv-clean
  else
    echo "[of-paraview] pv-clean niet gevonden en container heeft geen ParaView. Installeer 'paraview' op host of gebruik een image met ParaView." >&2
    exit 1
  fi
else
  exit $status
fi


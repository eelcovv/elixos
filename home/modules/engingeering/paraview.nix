# home/modules/engingeering/paraview.nix
{
  pkgs,
  config,
  lib,
  ...
}: {
  # Containerized ParaView launcher (Wayland/X11 passthrough)
  home.file.".local/bin/of-paraview" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Run ParaView from the OpenFOAM container with GUI passthrough (Wayland or X11).
      # Usage: cd /path/to/case && of-paraview
      set -euo pipefail

      IMAGE="''${IMAGE:-docker.io/opencfd/openfoam-default:2406}"

      # Common mounts: project directory and GPU devices for acceleration
      mounts=(
        -v "$PWD":/case -w /case
        --device /dev/dri
      )

      # Detect Wayland or X11 and set up environment/mounts accordingly
      if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -n "''${XDG_RUNTIME_DIR:-}" ] && [ -S "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}" ]; then
        echo "[of-paraview] Using Wayland socket: $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
        extra_env=( -e WAYLAND_DISPLAY -e XDG_RUNTIME_DIR -e HOME=/root -e QT_QPA_PLATFORM=wayland )
        # Map the Wayland socket into the container (root inside: /run/user/0)
        extra_mounts=( -v "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}:/run/user/0/''${WAYLAND_DISPLAY}" )
      else
        echo "[of-paraview] Falling back to X11 via XWayland (DISPLAY=$DISPLAY)"
        extra_env=( -e DISPLAY -e HOME=/root -e QT_QPA_PLATFORM=xcb )
        extra_mounts=( -v /tmp/.X11-unix:/tmp/.X11-unix )
      fi

      # Optional theming mounts (fonts/icons); harmless if missing
      theme_mounts=(
        -v /run/fonts:/run/fonts:ro
        -v /usr/share/fonts:/usr/share/fonts:ro
        -v /nix/store:/nix/store:ro
      )

      # Run ParaView inside the container
      exec podman run --rm -it \
        --user 0:0 \
        "''${mounts[@]}" "''${extra_mounts[@]}" "''${theme_mounts[@]}" \
        "''${extra_env[@]}" \
        "$IMAGE" \
        bash -lc 'for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f "$p" ]; then source "$p" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; paraview'
    '';
  };

  # Host ParaView launcher with a "clean" environment (avoids protobuf/Qt clashes)
  home.file.".local/bin/pv-clean" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Start host ParaView with a clean environment to avoid protobuf descriptor clashes.
      # Preserves PATH/DISPLAY/XAUTHORITY so it can show a GUI.
      set -euo pipefail

      export PATH="''${PATH}"
      [ -n "''${DISPLAY:-}" ] && export DISPLAY="''${DISPLAY}"
      [ -n "''${XAUTHORITY:-}" ] && export XAUTHORITY="''${XAUTHORITY}"

      # Unset common troublemakers
      unset LD_LIBRARY_PATH
      unset QT_PLUGIN_PATH
      unset QT_QPA_PLATFORMTHEME
      unset QT_STYLE_OVERRIDE
      unset GTK_PATH
      unset GIO_EXTRA_MODULES

      exec paraview "$@"
    '';
  };
}

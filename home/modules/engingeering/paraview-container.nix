# home/modules/engingeering/paraview.nix
{
  pkgs,
  config,
  lib,
  ...
}: {
  # Containerized ParaView launcher (Wayland/X11 passthrough) — robust mounts
  home.file.".local/bin/of-paraview" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Run ParaView from the OpenFOAM container with GUI passthrough (Wayland or X11).
      # Usage: cd /path/to/case && of-paraview
      set -euo pipefail

      IMAGE="''${IMAGE:-docker.io/opencfd/openfoam-default:2406}"

      # Base mounts (project dir)
      mounts=( -v "$PWD":/case -w /case )

      # GPU devices if present (Intel/AMD/NVIDIA via libglvnd); ignore if missing
      if [ -e /dev/dri ]; then
        mounts+=( --device /dev/dri )
      fi

      # Wayland vs X11 detection
      extra_env=( -e HOME=/root )
      extra_mounts=()
      if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -n "''${XDG_RUNTIME_DIR:-}" ] \
         && [ -S "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}" ]; then
        echo "[of-paraview] Using Wayland socket: $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
        extra_env+=( -e WAYLAND_DISPLAY -e XDG_RUNTIME_DIR -e QT_QPA_PLATFORM=wayland -e XDG_SESSION_TYPE=wayland )
        # Map host user's Wayland socket into container root's runtime dir
        extra_mounts+=( -v "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}:/run/user/0/''${WAYLAND_DISPLAY}" )
      else
        echo "[of-paraview] Falling back to X11 (DISPLAY=$DISPLAY)"
        extra_env+=( -e DISPLAY -e QT_QPA_PLATFORM=xcb )
        if [ -d /tmp/.X11-unix ]; then
          extra_mounts+=( -v /tmp/.X11-unix:/tmp/.X11-unix )
        fi
      fi

      # Optional theming mounts — only if they exist
      theme_mounts=()
      [ -d /usr/share/fonts ] && theme_mounts+=( -v /usr/share/fonts:/usr/share/fonts:ro )
      [ -d /run/fonts ] && theme_mounts+=( -v /run/fonts:/run/fonts:ro )
      [ -d /usr/share/icons ] && theme_mounts+=( -v /usr/share/icons:/usr/share/icons:ro )
      # Nix store is immutable; mounting read-only is safe, but not strictly nodig
      [ -d /nix/store ] && theme_mounts+=( -v /nix/store:/nix/store:ro )

      # Launch ParaView inside the OpenFOAM image
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

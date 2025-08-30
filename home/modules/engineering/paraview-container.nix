{
  config,
  pkgs,
  lib,
  ...
}: {
  home.file.".local/bin/pv-container" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # ParaView via container met Wayland/X11 passthrough (zonder OpenFOAM)
      set -euo pipefail

      IMAGE="''${IMAGE:-docker.io/kitware/paraview:latest}"

      # Project map mount
      mounts=( -v "$PWD":/case -w /case )

      # GPU doorgeven (Intel/AMD/NVIDIA via /dev/dri)
      if [ -e /dev/dri ]; then
        mounts+=( --device /dev/dri )
      fi

      # Wayland/X11 detectie
      extra_env=( -e HOME=/root )
      extra_mounts=()
      if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -n "''${XDG_RUNTIME_DIR:-}" ] \
         && [ -S "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}" ]; then
        echo "[pv-container] Wayland: ''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}"
        extra_env+=( -e WAYLAND_DISPLAY -e XDG_RUNTIME_DIR -e QT_QPA_PLATFORM=wayland -e XDG_SESSION_TYPE=wayland )
        extra_mounts+=( -v "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}:/run/user/0/''${WAYLAND_DISPLAY}" )
      else
        echo "[pv-container] X11 fallback (DISPLAY=''${DISPLAY:-})"
        extra_env+=( -e DISPLAY -e QT_QPA_PLATFORM=xcb )
        if [ -d /tmp/.X11-unix ]; then
          extra_mounts+=( -v /tmp/.X11-unix:/tmp/.X11-unix )
        fi
        if [ -n "''${XAUTHORITY:-}" ]; then
          extra_env+=( -e XAUTHORITY )
          mounts+=( -v "''${XAUTHORITY}:''${XAUTHORITY}:ro" )
        fi
      fi

      # Optionele theming mounts
      theme_mounts=()
      [ -d /usr/share/fonts ] && theme_mounts+=( -v /usr/share/fonts:/usr/share/fonts:ro )
      [ -d /usr/share/icons ] && theme_mounts+=( -v /usr/share/icons:/usr/share/icons:ro )
      [ -d /nix/store ] && theme_mounts+=( -v /nix/store:/nix/store:ro )

      # Start ParaView
      exec podman run --rm -it \
        --user 0:0 \
        "''${mounts[@]}" "''${extra_mounts[@]}" "''${theme_mounts[@]}" \
        "''${extra_env[@]}" \
        "$IMAGE" \
        paraview "$@"
    '';
  };
}

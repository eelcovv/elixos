# home/modules/engingeering/paraview.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.engineering.paraview;
in {
  options.engineering.paraview = {
    enable = lib.mkEnableOption "ParaView tools (host + optional container launcher)";

    host = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable host-side ParaView support.";
      };
      installPackage = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install pkgs.paraview on the host.";
      };
      installPvClean = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install the 'pv-clean' launcher that starts ParaView in a clean environment.";
      };
      wrapDefault = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install a 'paraview' shim that delegates to pv-clean to avoid protobuf/Qt clashes.";
      };
    };

    container = {
      enable = lib.mkEnableOption "Enable pv-container (ParaView in a container)";
      image = lib.mkOption {
        type = lib.types.str;
        default = "local/paraview:24.04";
        description = ''
          Container image to run for pv-container.
          Tip: build once with:
            FROM ubuntu:24.04
            ENV DEBIAN_FRONTEND=noninteractive
            RUN apt-get update && \
                apt-get install -y --no-install-recommends paraview mesa-utils && \
                rm -rf /var/lib/apt/lists/*
          Then:
            podman build -t local/paraview:24.04 -f Containerfile
        '';
      };
      runtime = lib.mkOption {
        type = lib.types.enum ["podman" "docker"];
        default = "podman";
        description = "Container runtime to use for pv-container.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure required packages are present
    home.packages =
      (lib.optionals (cfg.host.enable && cfg.host.installPackage) [pkgs.paraview])
      ++ (lib.optionals (cfg.container.enable && cfg.container.runtime == "podman") [pkgs.podman])
      ++ (lib.optionals (cfg.container.enable && cfg.container.runtime == "docker") [pkgs.docker]);

    # Ensure ~/.local/bin takes precedence in PATH so our wrappers are found first
    home.sessionPath = lib.mkBefore ["${config.home.homeDirectory}/.local/bin"];

    # Clean-env host launcher to avoid protobuf/Qt clashes
    home.file.".local/bin/pv-clean" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Ultra-clean env to avoid protobuf/Qt clashes.
        set -euo pipefail

        # Minimal PATH for NixOS
        PATH_MIN="''${HOME}/.nix-profile/bin:/etc/profiles/per-user/''${USER}/bin:/run/current-system/sw/bin"

        # Disable Qt plugin discovery
        QT_NOWHERE="/dev/null/qt-plugins"

        exec env -i \
          HOME="''${HOME}" \
          USER="''${USER}" \
          PATH="''${PATH_MIN}" \
          DISPLAY="''${DISPLAY:-}" \
          XAUTHORITY="''${XAUTHORITY:-}" \
          WAYLAND_DISPLAY="" \
          XDG_RUNTIME_DIR="" \
          QT_QPA_PLATFORM="xcb" \
          QT_QPA_PLATFORMTHEME="" \
          QT_STYLE_OVERRIDE="" \
          QT_PLUGIN_PATH="''${QT_NOWHERE}" \
          QML2_IMPORT_PATH="''${QT_NOWHERE}" \
          QML_IMPORT_PATH="''${QT_NOWHERE}" \
          LD_LIBRARY_PATH="" \
          LD_PRELOAD="" \
          LIBGL_ALWAYS_SOFTWARE=0 \
          paraview "''$@"
      '';
    };

    home.file.".local/bin/paraview" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec env QT_QPA_PLATFORM=xcb pv-clean "''$@"
      '';
    };

    # Container launcher with Wayland/X11 + /dev/dri passthrough
    home.file.".local/bin/pv-container" = lib.mkIf cfg.container.enable {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # ParaView via container (Wayland/X11 passthrough, GPU via /dev/dri)
        set -euo pipefail

        RUNTIME="${cfg.container.runtime}"
        IMAGE="${cfg.container.image}"

        run() {
          if [ "''${RUNTIME}" = "podman" ]; then
            exec podman "''$@"
          else
            exec docker "''$@"
          fi
        }

        # Base mounts (project workdir)
        mounts=( -v "''${PWD}":/case -w /case )

        # GPU devices (Intel/AMD/NVIDIA via /dev/dri)
        if [ -e /dev/dri ]; then
          mounts+=( --device /dev/dri )
        fi

        # Wayland/X11 detection
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
            extra_env+=( -e XAUTHORITY="''${XAUTHORITY}" )
            mounts+=( -v "''${XAUTHORITY}:''${XAUTHORITY}:ro" )
          fi
        fi

        # Optional theming mounts (best-effort)
        theme_mounts=()
        [ -d /usr/share/fonts ] && theme_mounts+=( -v /usr/share/fonts:/usr/share/fonts:ro )
        [ -d /usr/share/icons ] && theme_mounts+=( -v /usr/share/icons:/usr/share/icons:ro )
        [ -d /nix/store ] && theme_mounts+=( -v /nix/store:/nix/store:ro )

        # Launch ParaView inside the container
        run run --rm -it \
          --user 0:0 \
          "''${mounts[@]}" "''${extra_mounts[@]}" "''${theme_mounts[@]}" \
          "''${extra_env[@]}" \
          "''${IMAGE}" \
          paraview "''$@"
      '';
    };
  };
}

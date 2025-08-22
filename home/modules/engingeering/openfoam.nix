# home/modules/engingeering/openfoam.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.engineering.openfoam;

  # Compose full image reference from options
  imageRef = "${cfg.image}:${cfg.tag}";
in {
  # -----------------------------
  # Module options (public API)
  # -----------------------------
  options.engineering.openfoam = {
    enable = mkEnableOption "OpenFOAM helpers (Podman-based)";

    # OpenCFD tags like: 2312, 2406, 2412, ...
    tag = mkOption {
      type = types.str;
      default = "2406";
      description = "OpenCFD OpenFOAM image tag (e.g., 2312, 2406, 2412).";
    };

    image = mkOption {
      type = types.str;
      default = "docker.io/opencfd/openfoam-default";
      description = "Container image base for OpenFOAM.";
    };
  };

  # -----------------------------
  # Module implementation
  # -----------------------------
  config = mkIf cfg.enable {
    # Tools in PATH for the user
    home.packages = with pkgs; [
      podman
      skopeo
      coreutils
      bashInteractive
    ];

    # of-shell: verbose + keep-id with timeout + fallback, with environment toggle
    home.file.".local/bin/of-shell" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Interactive OpenFOAM shell; try keep-id (with timeout), fallback if needed.
        set -euo pipefail

        # Allow forcing fallback: export OPENFOAM_NO_KEEPID=1
        if [ "''${OPENFOAM_NO_KEEPID:-0}" = "1" ]; then
          echo "[of-shell] MODE=fallback (OPENFOAM_NO_KEEPID=1)"
          exec podman run --rm -it \
            --user "$(id -u):$(id -g)" \
            -v "$PWD":/case -w /case \
            ${imageRef} \
            bash -lc 'for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f "$p" ]; then source "$p" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo "[of-shell] cwd=$(pwd), uid=$(id -u), gid=$(id -g)"; exec bash -i'
        fi

        echo "[of-shell] Trying MODE=keep-id (20s timeout)…"
        if timeout 20s podman run --rm -it \
          --userns=keep-id \
          --user "$(id -u):$(id -g)" \
          -v "$PWD":/case -w /case \
          ${imageRef} \
          bash -lc 'for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f "$p" ]; then source "$p" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo "[of-shell] MODE=keep-id OK, cwd=$(pwd), uid=$(id -u), gid=$(id -g)"; exec bash -i'
        then
          exit 0
        fi

        echo "[of-shell] keep-id failed or timed out → MODE=fallback"
        exec podman run --rm -it \
          --user "$(id -u):$(id -g)" \
          -v "$PWD":/case -w /case \
          ${imageRef} \
          bash -lc 'for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f "$p" ]; then source "$p" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo "[of-shell] MODE=fallback OK, cwd=$(pwd), uid=$(id -u), gid=$(id -g)"; exec bash -i'
      '';
    };

    # of-run: same behavior for one-shot commands
    home.file.".local/bin/of-run" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Run an OpenFOAM command; try keep-id (with timeout), fallback if needed.
        set -euo pipefail
        if [ $# -lt 1 ]; then
          echo "Usage: of-run <command> [args...]" >&2
          exit 2
        fi
        cmd="$*"

        # Allow forcing fallback: export OPENFOAM_NO_KEEPID=1
        if [ "''${OPENFOAM_NO_KEEPID:-0}" = "1" ]; then
          echo "[of-run] MODE=fallback (OPENFOAM_NO_KEEPID=1) → $cmd"
          exec podman run --rm \
            --user "$(id -u):$(id -g)" \
            -v "$PWD":/case -w /case \
            ${imageRef} \
            bash -lc "for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f \"\$p\" ]; then source \"\$p\" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo \"[of-run] cwd=\$(pwd), uid=\$(id -u), gid=\$(id -g)\"; echo \"[of-run] \$cmd\"; eval \$cmd"
        fi

        echo "[of-run] Trying MODE=keep-id (20s timeout) → $cmd"
        if timeout 20s podman run --rm \
          --userns=keep-id \
          --user "$(id -u):$(id -g)" \
          -v "$PWD":/case -w /case \
          ${imageRef} \
          bash -lc "for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f \"\$p\" ]; then source \"\$p\" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo \"[of-run] MODE=keep-id OK, cwd=\$(pwd), uid=\$(id -u), gid=\$(id -g)\"; echo \"[of-run] \$cmd\"; eval \$cmd"
        then
          exit 0
        fi

        echo "[of-run] keep-id failed or timed out → MODE=fallback → $cmd"
        exec podman run --rm \
          --user "$(id -u):$(id -g)" \
          -v "$PWD":/case -w /case \
          ${imageRef} \
          bash -lc "for p in /usr/lib/openfoam/openfoam*/etc/bashrc /opt/OpenFOAM-*/etc/bashrc /opt/openfoam*/etc/bashrc /usr/share/openfoam*/etc/bashrc /usr/bin/openfoam; do if [ -f \"\$p\" ]; then source \"\$p\" >/dev/null 2>&1 || true; break; fi; done; cd /case || exit 1; echo \"[of-run] MODE=fallback OK, cwd=\$(pwd), uid=\$(id -u), gid=\$(id -g)\"; echo \"[of-run] \$cmd\"; eval \$cmd"
      '';
    };

    # mkfoam helper (tiny convenience)
    home.file.".local/bin/mkfoam" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Create a .foam file for ParaView to open the case directory directly.
        set -euo pipefail
        name="''${1:-case}"
        touch "''${name}.foam"
        echo "Created: ''${name}.foam (open in ParaView)."
      '';
    };
  };
}

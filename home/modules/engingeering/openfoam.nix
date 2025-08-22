# home/modules/engingeering/openfoam.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.engineering.openfoam;
  imageRef = "${cfg.image}:${cfg.tag}";

  # Source OpenFOAM environment inside the container (best-effort)
  # IMPORTANT: escape $ to avoid expansion by the outer shell (set -u)
  sourceOF = ''
    for p in \
      /usr/lib/openfoam/openfoam*/etc/bashrc \
      /opt/OpenFOAM-*/etc/bashrc \
      /opt/openfoam*/etc/bashrc \
      /usr/share/openfoam*/etc/bashrc \
      /usr/bin/openfoam \
    ; do
      if [ -f "\$p" ]; then
        # shellcheck source=/dev/null
        source "\$p" >/dev/null 2>&1 || true
        break
      fi
    done
  '';

  # Recognize the specific keep-id failure so we can fallback
  fallbackGuard = ''
    err="$1"
    case "$err" in
      *"creating an ID-mapped copy of layer"*|*storage-chown-by-maps*|*lchown\ etc/gshadow* )
        exit 99
        ;;
    esac
    exit 1
  '';
in {
  options.engineering.openfoam = {
    enable = mkEnableOption "OpenFOAM helpers (Podman-based)";

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

  config = mkIf cfg.enable {
    home.packages = [pkgs.podman];

    # of-shell: try keep-id first, fallback on known error
    home.file.".local/bin/of-shell" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Interactive OpenFOAM shell; try keep-id first, then fallback without keep-id if needed.
        set -euo pipefail

        run_keepid=(
          podman run --rm -it
          --userns=keep-id
          --user "$(id -u):$(id -g)"
          -v "$PWD":/case -w /case
          ${imageRef}
          bash -lc '${sourceOF}; cd /case || exit 1; exec bash -i'
        )

        if ! out="$("''${run_keepid[@]}" 2>&1)"; then
          echo "$out" | bash -c '${fallbackGuard}' || { echo "$out" >&2; exit 1; }
          exec podman run --rm -it \
            --user "$(id -u):$(id -g)" \
            -v "$PWD":/case -w /case \
            ${imageRef} \
            bash -lc '${sourceOF}; cd /case || exit 1; exec bash -i'
        fi
      '';
    };

    # of-run: same fallback logic for one-shot commands
    home.file.".local/bin/of-run" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Run an OpenFOAM command; try keep-id first, then fallback without keep-id if needed.
        set -euo pipefail
        if [ $# -lt 1 ]; then
          echo "Usage: of-run <command> [args...]" >&2
          exit 2
        fi
        cmd="$*"

        run_keepid=(
          podman run --rm
          --userns=keep-id
          --user "$(id -u):$(id -g)"
          -v "$PWD":/case -w /case
          ${imageRef}
          bash -lc "${sourceOF}; cd /case || exit 1; echo \"[of-run] $cmd\"; eval $cmd"
        )

        if ! out="$("''${run_keepid[@]}" 2>&1)"; then
          echo "$out" | bash -c '${fallbackGuard}' || { echo "$out" >&2; exit 1; }
          exec podman run --rm \
            --user "$(id -u):$(id -g)" \
            -v "$PWD":/case -w /case \
            ${imageRef} \
            bash -lc "${sourceOF}; cd /case || exit 1; echo \"[of-run] $cmd\"; eval $cmd"
        fi
      '';
    };

    # mkfoam helper
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
